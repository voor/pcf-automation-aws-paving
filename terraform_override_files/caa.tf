resource "aws_route53_record" "letsencrypt_caa" {
  zone_id = "${module.infra.zone_id}"
  name    = ""
  type    = "CAA"
  ttl     = "300"
  records = ["0 issue \"letsencrypt.org\""]
}
