output "application_url" {
  description = "URL where the application can be accessed"
  value       = "http://${module.retail_app_ecs.alb_dns_name}"
}

output "environment_name" {
  value       = local.standard_environment_name
  description = "The environment name used for all resources"
}

# Output the Datadog DBM cluster ARN
output "datadog_dbm_cluster_arn" {
  description = "ARN of the Datadog DBM ECS cluster"
  value       = var.enable_database_monitoring ? aws_ecs_cluster.datadog_dbm[0].arn : ""
}

# Output the Datadog DBM cluster name
output "datadog_dbm_cluster_name" {
  description = "Name of the Datadog DBM ECS cluster"
  value       = var.enable_database_monitoring ? aws_ecs_cluster.datadog_dbm[0].name : ""
}

# Output the catalog database admin credentials ARN
output "catalog_db_admin_creds_arn" {
  description = "ARN of the catalog database admin credentials secret"
  value       = var.enable_database_monitoring && var.enable_datadog ? module.datadog[0].catalog_db_admin_creds_arn : ""
}

# Output the orders database admin credentials ARN
output "orders_db_admin_creds_arn" {
  description = "ARN of the orders database admin credentials secret"
  value       = var.enable_database_monitoring && var.enable_datadog ? module.datadog[0].orders_db_admin_creds_arn : ""
}
