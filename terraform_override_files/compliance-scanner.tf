
output "compliance_scanner_bucket" {
  value = "${aws_s3_bucket.compliance_scanner_bucket.id}"
}

// Harbor s3 backing bucket
resource "aws_s3_bucket" "compliance_scanner_bucket" {
  bucket_prefix = "${var.env_name}-compliance-scanner-bucket"
  force_destroy = true
  region        = "${var.region}"

  tags = "${merge(var.tags, map("Name", "${var.env_name} Compliance Scanner S3 Bucket"))}"
}

resource "aws_s3_bucket_public_access_block" "compliance_scanner_bucket_block" {
  bucket = "${aws_s3_bucket.compliance_scanner_bucket.id}"

  block_public_acls   = true
  block_public_policy = true
}


// Harbor iam instance role
data "aws_iam_policy_document" "compliance_scanner_policy" {
  statement {
    sid = "ComplianceScannerS3PolicyToBucket"

    effect = "Allow"

    actions = [
      "s3:ListBucketMultipartUploads",
      "s3:ListBucket",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:GetObject",
      "s3:AbortMultipartUpload",
      "s3:DeleteObject",
      "s3:ListMultipartUploadParts",
    ]

    resources = [
      "${aws_s3_bucket.compliance_scanner_bucket.arn}",
      "arn:aws:s3:*:*:job/*",
      "${aws_s3_bucket.compliance_scanner_bucket.arn}/*",
    ]compliance_scanner
  }
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "compliance_scanner_policy" {
  name   = "${var.env_name}_compliance_scanner-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.compliance_scanner_policy.json}"
}

resource "aws_iam_role" "compliance_scanner_role" {
  name = "${var.env_name}_compliance_scanner"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "compliance_scanner_attachment" {
  role       = "${aws_iam_role.compliance_scanner_role.name}"
  policy_arn = "${aws_iam_policy.compliance_scanner_policy.arn}"
}

resource "aws_iam_instance_profile" "compliance_scanner_profile" {
  name = "${var.env_name}_compliance_scanner"
  role = "${aws_iam_role.compliance_scanner_role.name}"

  lifecycle {
    ignore_changes = ["name"]
  }
}

output "compliance_scanner_profile_name" {
  value = "${aws_iam_instance_profile.compliance_scanner_profile.name}"
}

// Allow BOSH Director to set instance profile
data "aws_iam_policy_document" "ops_manager_compliance_scanner" {
  statement {
    sid     = "AllowToCreateInstanceWithHarborInstanceProfile"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      "${aws_iam_role.compliance_scanner_role.arn}",
    ]
  }
}

resource "aws_iam_policy" "ops_manager_compliance_scanner_policy" {
  name        = "${var.env_name}_ops_manager_compliance_scanner_policy"
  description = "Allow ops manager to pass compliance scanner role"
  policy      = "${data.aws_iam_policy_document.ops_manager_compliance_scanner.json}"
}

resource "aws_iam_role_policy_attachment" "ops_manager_policy" {
  role       = "${var.env_name}_om_role"
  policy_arn = "${aws_iam_policy.ops_manager_compliance_scanner_policy.arn}"
}
