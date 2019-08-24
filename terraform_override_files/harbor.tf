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
