variable "name" {}
variable "cidr" {}
variable "azs" { type = list(string) }

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.13"

  name = "${var.name}-vpc"
  cidr = var.cidr
  azs  = var.azs

  public_subnets  = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, i)]
  private_subnets = [for i, _ in var.azs : cidrsubnet(var.cidr, 8, i + 10)]

  enable_nat_gateway   = true
  single_nat_gateway   = true # cost saver for lab; one per AZ in prod
  enable_dns_hostnames = true
}

output "vpc_id" { value = module.vpc.vpc_id }
output "public_subnets" { value = module.vpc.public_subnets }
output "private_subnets" { value = module.vpc.private_subnets }
