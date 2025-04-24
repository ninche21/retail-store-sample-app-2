variable "environment_name" {
  description = "Name of the environment"
  type        = string
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  sensitive   = true
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

# Create a secret for the Datadog API key
resource "aws_secretsmanager_secret" "datadog_api_key" {
  name        = "${var.environment_name}-datadog-api-key"
  description = "Datadog API key for ${var.environment_name} environment"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id     = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = var.datadog_api_key
}

output "datadog_api_key_arn" {
  description = "ARN of the Datadog API key secret"
  value       = aws_secretsmanager_secret.datadog_api_key.arn
}
