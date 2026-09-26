output "alb_dns_name" {
  description = "Public URL of the application"
  value       = module.ecs.alb_dns_name
}

output "rds_endpoint" {
  description = "Private RDS endpoint (not reachable from the internet)"
  value       = module.rds.address
}

output "ecs_cluster_name" {
  value = module.ecs.cluster_name
}
