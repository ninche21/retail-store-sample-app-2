output "application_url" {
  description = "URL where the application can be accessed"
  value       = "http://${module.retail_app_ecs.ui_service_url}"
}

output "environment_name" {
  value       = local.standard_environment_name
  description = "The environment name used for all resources"
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
