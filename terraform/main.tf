data "aws_availability_zones" "available" { state = "available" }

locals {
  azs = slice(data.aws_availability_zones.available.names, 0, 2)
}

module "vpc" {
  source = "./modules/vpc"
  name   = var.name
  cidr   = var.vpc_cidr
  azs    = local.azs
}

# ---- TLS certificate: ACM (real domain) or self-signed (lab) ----
resource "aws_acm_certificate" "this" {
  count             = var.domain_name != "" ? 1 : 0
  domain_name       = var.domain_name
  validation_method = "DNS"
  lifecycle { create_before_destroy = true }
}

resource "aws_route53_record" "validation" {
  for_each = var.domain_name != "" ? {
    for o in aws_acm_certificate.this[0].domain_validation_options : o.domain_name => o
  } : {}
  zone_id = var.route53_zone_id
  name    = each.value.resource_record_name
  type    = each.value.resource_record_type
  records = [each.value.resource_record_value]
  ttl     = 60
}

resource "aws_acm_certificate_validation" "this" {
  count                   = var.domain_name != "" ? 1 : 0
  certificate_arn         = aws_acm_certificate.this[0].arn
  validation_record_fqdns = [for r in aws_route53_record.validation : r.fqdn]
}

resource "tls_private_key" "lab" {
  count     = var.domain_name == "" ? 1 : 0
  algorithm = "RSA"
}

resource "tls_self_signed_cert" "lab" {
  count           = var.domain_name == "" ? 1 : 0
  private_key_pem = tls_private_key.lab[0].private_key_pem
  subject {
    common_name = "lab.local"
  }
  validity_period_hours = 8760
  allowed_uses          = ["key_encipherment", "digital_signature", "server_auth"]
}

resource "aws_acm_certificate" "lab" {
  count            = var.domain_name == "" ? 1 : 0
  private_key      = tls_private_key.lab[0].private_key_pem
  certificate_body = tls_self_signed_cert.lab[0].cert_pem
}

locals {
  cert_arn = var.domain_name != "" ? aws_acm_certificate_validation.this[0].certificate_arn : aws_acm_certificate.lab[0].arn
}

module "alb" {
  source          = "./modules/alb"
  name            = var.name
  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  certificate_arn = local.cert_arn
}

module "asg" {
  source             = "./modules/asg"
  name               = var.name
  vpc_id             = module.vpc.vpc_id
  subnets            = module.vpc.private_subnets
  alb_sg_id          = module.alb.sg_id
  target_group_arn   = module.alb.target_group_arn
  instance_type      = var.instance_type
  ami_id             = var.ami_id
  app_version        = var.app_version
  min_size           = var.min_size
  max_size           = var.max_size
  desired_size       = var.desired_size
  alb_resource_label = "${module.alb.arn_suffix}/${module.alb.target_group_arn_suffix}"
}

module "monitoring" {
  source                  = "./modules/monitoring"
  name                    = var.name
  region                  = var.region
  alb_arn_suffix          = module.alb.arn_suffix
  target_group_arn_suffix = module.alb.target_group_arn_suffix
  asg_name                = module.asg.asg_name
  alarm_email             = var.alarm_email
}

resource "aws_route53_record" "app" {
  count   = var.domain_name != "" ? 1 : 0
  zone_id = var.route53_zone_id
  name    = var.domain_name
  type    = "A"
  alias {
    name                   = module.alb.dns_name
    zone_id                = module.alb.zone_id
    evaluate_target_health = true
  }
}
