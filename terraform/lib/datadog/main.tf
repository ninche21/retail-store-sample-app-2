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

variable "datadog_integration_role_name" {
  description = "Name of the Datadog integration IAM role"
  type        = string
  default     = "DatadogIntegrationRole"
}

variable "datadog_forwarder_lambda_arn" {
  description = "ARN of the Datadog Forwarder Lambda function"
  type        = string
  default     = ""
}

# Generate a random string to append to resource names
resource "random_string" "suffix" {
  length  = 4
  special = false
  upper   = false
}

# Create a secret for the Datadog API key
resource "aws_secretsmanager_secret" "datadog_api_key" {
  name        = "${var.environment_name}-datadog-api-key-${random_string.suffix.result}"
  description = "Datadog API key for ${var.environment_name} environment"
  tags        = var.tags
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id     = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = var.datadog_api_key
}

# Attach CloudWatchLogsReadOnlyAccess policy to the Datadog integration role
resource "aws_iam_role_policy_attachment" "datadog_cloudwatch_logs" {
  count      = var.datadog_integration_role_name != "" ? 1 : 0
  role       = var.datadog_integration_role_name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsReadOnlyAccess"
}

output "datadog_api_key_arn" {
  description = "ARN of the Datadog API key secret"
  value       = aws_secretsmanager_secret.datadog_api_key.arn
}
