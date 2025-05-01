# This file provides a random philosopher/mathematician name to append to resource names
# to ensure uniqueness across multiple deployments

locals {
  # List of famous philosophers and mathematicians
  philosopher_names = [
    "aristotle", "plato", "socrates", "descartes", "kant", 
    "newton", "euler", "gauss", "hilbert", "pascal", 
    "leibniz", "pythagoras", "euclid", "archimedes", "fibonacci", 
    "fermat", "riemann", "turing", "godel", "russell",
    "wittgenstein", "hume", "locke", "spinoza", "aquinas"
  ]
  
  # Generate a random 4-character string for sensitive resources only
  random_suffix = random_string.suffix.result
  
  # Select a random name from the list
  random_name = local.philosopher_names[random_integer.name_index.result]
  
  # Create the standard environment name with just the philosopher name
  standard_environment_name = "${var.environment_name}-${local.random_name}"
  
  # Create names for sensitive resources with additional random suffix
  sensitive_resource_name = "${var.environment_name}-${local.random_name}-${local.random_suffix}"
  
  # Use the standard environment name as the full environment name
  full_environment_name = local.standard_environment_name
}

# Generate a random 4-character string for sensitive resources
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Generate a random index to select a name
resource "random_integer" "name_index" {
  min = 0
  max = length(local.philosopher_names) - 1
}

# Output the selected name for reference
output "random_name" {
  value       = local.random_name
  description = "The randomly selected philosopher/mathematician name"
}

output "random_suffix" {
  value       = local.random_suffix
  description = "The randomly generated suffix for sensitive resources"
}

output "standard_environment_name" {
  value       = local.standard_environment_name
  description = "The standard environment name with philosopher name"
}

output "sensitive_resource_name" {
  value       = local.sensitive_resource_name
  description = "The name for sensitive resources with additional random suffix"
}
