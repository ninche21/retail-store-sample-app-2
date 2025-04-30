variable "environment_name" {
  type        = string
  default     = "retail-store-ecs"
  description = "Name of the environment"
}

variable "container_image_overrides" {
  type = object({
    default_repository = optional(string)
    default_tag        = optional(string)

    ui       = optional(string)
    catalog  = optional(string)
    cart     = optional(string)
    checkout = optional(string)
    orders   = optional(string)
  })
  default     = {}
  description = "Object that encapsulates any overrides to default values"
}

# Datadog integration variables
variable "enable_datadog" {
  description = "Enable Datadog integration"
  type        = bool
  default     = false
}

variable "datadog_api_key" {
  description = "Datadog API key"
  type        = string
  default     = ""
  sensitive   = true
}

variable "datadog_integration_role_name" {
  description = "Name of the Datadog integration IAM role"
  type        = string
  default     = "DatadogIntegrationRole"
}

variable "datadog_forwarder_lambda_arn" {
  description = "ARN of the Datadog Forwarder Lambda function"
  type        = string
  # No default - this should be provided by the user when enable_datadog is true
}

