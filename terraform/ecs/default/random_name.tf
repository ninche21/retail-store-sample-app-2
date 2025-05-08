locals {
  # Use the environment name directly without adding random names
  standard_environment_name = var.environment_name
  full_environment_name = var.environment_name
  
  # Generate a random 4-character string for sensitive resources only
  random_suffix = random_string.suffix.result
  
  # Create names for sensitive resources with additional random suffix
  sensitive_resource_name = "${var.environment_name}-${local.random_suffix}"
}

# Generate a random 4-character string for sensitive resources
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

output "standard_environment_name" {
  value       = local.standard_environment_name
  description = "The standard environment name"
}

output "sensitive_resource_name" {
  value       = local.sensitive_resource_name
  description = "The name for sensitive resources with additional random suffix"
}
