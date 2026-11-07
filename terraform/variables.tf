variable "region" { default = "us-east-1" }
variable "name" { default = "webapp" }
variable "vpc_cidr" { default = "10.0.0.0/16" }
variable "instance_type" { default = "t3.micro" }
variable "min_size" { default = 2 }
variable "max_size" { default = 6 }
variable "desired_size" { default = 2 }
variable "ami_id" {
  description = "Baked AMI (Packer). Empty = stock AL2023 + user-data bootstrap."
  default     = ""
}
variable "app_version" { default = "1.0.0" }
variable "domain_name" {
  description = "Domain for ACM cert (needs a Route53 hosted zone). Empty = self-signed lab cert."
  default     = ""
}
variable "route53_zone_id" { default = "" }
variable "alarm_email" { default = "" }
