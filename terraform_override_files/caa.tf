resource "aws_route53_record" "letsencrypt_caa" {
  zone_id = "${var.zone_id}"
  name    = ""
  type    = "CAA"
  ttl     = "300"
  records = ["0 issue \"letsencrypt.org\""]
}
