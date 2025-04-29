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
  
  # Select a random name from the list
  random_name = local.philosopher_names[random_integer.name_index.result]
  
  # Create the full environment name with the random name appended
  full_environment_name = "${var.environment_name}-${local.random_name}"
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

output "full_environment_name" {
  value       = local.full_environment_name
  description = "The full environment name with random philosopher/mathematician name appended"
}
