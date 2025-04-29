output "application_url" {
  description = "URL where the application can be accessed"
  value       = module.retail_app_ecs.ui_service_url
}

output "environment_name" {
  value       = local.full_environment_name
  description = "The environment name used for all resources"
}
