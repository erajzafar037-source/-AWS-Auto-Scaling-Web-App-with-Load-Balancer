output "alb_dns_name" { value = module.alb.dns_name }
output "app_url" { value = "https://${module.alb.dns_name}" }
output "asg_name" { value = module.asg.asg_name }
output "dashboard_url" { value = module.monitoring.dashboard_url }
output "vpc_id" { value = module.vpc.vpc_id }
