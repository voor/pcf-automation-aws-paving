output "harbor_endpoint" {
  value = "${element(concat(aws_route53_record.harbor_dns.*.name, list("")), 0)}"
}

output "harbor_bucket" {
  value = "${aws_s3_bucket.harbor_bucket.id}"
}

output "harbor_api_target_groups" {
  value = [
    "${aws_lb_target_group.harbor_443.name}",
    "${aws_lb_target_group.harbor_4443.name}",
  ]
}

output "harbor_lb_security_group" {
  value = "${aws_security_group.harbor_lb_security_group.name}"
}

// Allow access to Harbor
resource "aws_security_group" "harbor_lb_security_group" {
  name        = "${var.env_name}_harbor_lb_security_group"
  description = "Harbor LB Security Group"
  vpc_id      = "${module.infra.vpc_id}"

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 443
    to_port     = 443
  }

  ingress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "tcp"
    from_port   = 4443
    to_port     = 4443
  }

  egress {
    cidr_blocks = ["0.0.0.0/0"]
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
  }

  tags = "${merge(var.tags, map("Name", "${var.env_name}-harbor-lb-security-group"))}"
}

resource "aws_lb" "harbor_lb" {
  name                             = "${var.env_name}-harbor"
  load_balancer_type               = "network"
  enable_cross_zone_load_balancing = true
  internal                         = false
  subnets                          = ["${module.infra.public_subnet_ids}"]
}

resource "aws_lb_listener" "harbor_443" {
  load_balancer_arn = "${aws_lb.harbor_lb.arn}"
  port              = 443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.harbor_443.arn}"
  }
}

resource "aws_lb_target_group" "harbor_443" {
  name     = "${var.env_name}-harbor-tg-443"
  port     = 443
  protocol = "TCP"
  vpc_id   = "${module.infra.vpc_id}"

  health_check {
    healthy_threshold   = 6
    unhealthy_threshold = 6
    interval            = 10
    protocol            = "TCP"
  }
}

resource "aws_lb_listener" "harbor_4443" {
  load_balancer_arn = "${aws_lb.harbor_lb.arn}"
  port              = 4443
  protocol          = "TCP"

  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.harbor_4443.arn}"
  }
}

resource "aws_lb_target_group" "harbor_4443" {
  name     = "${var.env_name}-harbor-tg-4443"
  port     = 4443
  protocol = "TCP"
  vpc_id   = "${module.infra.vpc_id}"
}

// Harbor s3 backing bucket
resource "aws_s3_bucket" "harbor_bucket" {
  bucket_prefix = "${var.env_name}-harbor-bucket"
  force_destroy = true
  region        = "${var.region}"

  tags = "${merge(var.tags, map("Name", "${var.env_name} Harbor S3 Bucket"))}"
}

resource "aws_route53_record" "harbor_dns" {
  zone_id = "${module.infra.zone_id}"
  name    = "harbor.${var.env_name}.${var.dns_suffix}"
  type    = "A"

  alias {
    name                   = "${aws_lb.harbor_lb.dns_name}"
    zone_id                = "${aws_lb.harbor_lb.zone_id}"
    evaluate_target_health = true
  }

  count = "${var.use_route53}"
}

// Harbor iam instance role
data "aws_iam_policy_document" "harbor_policy" {
  statement {
    sid = "HarborS3Policy"

    actions = [
      "s3:PutAnalyticsConfiguration",
      "s3:GetObjectVersionTagging",
      "s3:CreateBucket",
      "s3:ReplicateObject",
      "s3:GetBucketObjectLockConfiguration",
      "s3:GetObjectAcl",
      "s3:PutLifecycleConfiguration",
      "s3:GetObjectVersionAcl",
      "s3:PutBucketAcl",
      "s3:PutObjectTagging",
      "s3:DeleteObject",
      "s3:DeleteObjectTagging",
      "s3:GetBucketPolicyStatus",
      "s3:GetObjectRetention",
      "s3:GetBucketWebsite",
      "s3:PutReplicationConfiguration",
      "s3:DeleteObjectVersionTagging",
      "s3:PutObjectLegalHold",
      "s3:GetBucketNotification",
      "s3:GetObjectLegalHold",
      "s3:PutBucketCORS",
      "s3:GetReplicationConfiguration",
      "s3:ListMultipartUploadParts",
      "s3:GetObject",
      "s3:PutBucketNotification",
      "s3:PutObject",
      "s3:DescribeJob",
      "s3:PutBucketLogging",
      "s3:PutObjectVersionAcl",
      "s3:GetAnalyticsConfiguration",
      "s3:GetObjectVersionForReplication",
      "s3:PutBucketObjectLockConfiguration",
      "s3:GetLifecycleConfiguration",
      "s3:ListBucketByTags",
      "s3:GetBucketTagging",
      "s3:GetInventoryConfiguration",
      "s3:PutAccelerateConfiguration",
      "s3:DeleteObjectVersion",
      "s3:GetBucketLogging",
      "s3:ListBucketVersions",
      "s3:ReplicateTags",
      "s3:RestoreObject",
      "s3:GetAccelerateConfiguration",
      "s3:ListBucket",
      "s3:GetBucketPolicy",
      "s3:PutEncryptionConfiguration",
      "s3:GetEncryptionConfiguration",
      "s3:GetObjectVersionTorrent",
      "s3:AbortMultipartUpload",
      "s3:GetBucketRequestPayment",
      "s3:PutBucketTagging",
      "s3:UpdateJobPriority",
      "s3:GetObjectTagging",
      "s3:GetMetricsConfiguration",
      "s3:PutBucketVersioning",
      "s3:PutObjectAcl",
      "s3:GetBucketPublicAccessBlock",
      "s3:ListBucketMultipartUploads",
      "s3:PutBucketPublicAccessBlock",
      "s3:PutMetricsConfiguration",
      "s3:PutObjectVersionTagging",
      "s3:GetBucketVersioning",
      "s3:UpdateJobStatus",
      "s3:GetBucketAcl",
      "s3:PutInventoryConfiguration",
      "s3:GetObjectTorrent",
      "s3:ObjectOwnerOverrideToBucketOwner",
      "s3:PutBucketRequestPayment",
      "s3:PutBucketWebsite",
      "s3:PutObjectRetention",
      "s3:GetBucketCORS",
      "s3:PutBucketPolicy",
      "s3:GetBucketLocation",
      "s3:GetObjectVersion",
      "s3:ReplicateDelete",
    ]

    resources = [
      "${aws_s3_bucket.harbor_bucket.arn}",
    ]
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

resource "aws_iam_policy" "harbor_policy" {
  name   = "${var.env_name}_harbor-policy"
  path   = "/"
  policy = "${data.aws_iam_policy_document.harbor_policy.json}"
}

resource "aws_iam_role" "harbor_role" {
  name = "${var.env_name}_harbor"

  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_iam_role_policy_attachment" "harbor_attachment" {
  role       = "${aws_iam_role.harbor_role.name}"
  policy_arn = "${aws_iam_policy.harbor_policy.arn}"
}

resource "aws_iam_instance_profile" "harbor_profile" {
  name = "${var.env_name}_harbor"
  role = "${aws_iam_role.harbor_role.name}"

  lifecycle {
    ignore_changes = ["name"]
  }
}

output "harbor_profile_name" {
  value = "${aws_iam_instance_profile.harbor_profile.name}"
}

// Allow BOSH Director to set instance profile
data "aws_iam_policy_document" "ops_manager_harbor" {
  statement {
    sid     = "AllowToCreateInstanceWithHarborInstanceProfile"
    effect  = "Allow"
    actions = ["iam:PassRole"]

    resources = [
      "${aws_iam_role.harbor_role.arn}",
    ]
  }
}

resource "aws_iam_policy" "ops_manager_harbor_policy" {
  name        = "ops_manager_harbor_policy"
  description = "Allow ops manager to pass harbor role"
  policy      = "${data.aws_iam_policy_document.ops_manager_harbor.json}"
}

data "aws_iam_role" "data_ops_manager_role" {
  name = "${var.env_name}_om_role"
}

resource "aws_iam_role_policy_attachment" "ops_manager_policy" {
  role       = "${data.aws_iam_role.data_ops_manager_role.name}"
  policy_arn = "${aws_iam_policy.ops_manager_harbor_policy.arn}"
}
