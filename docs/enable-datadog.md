# Enabling Datadog Monitoring for Retail Store Sample App

This guide explains how to add Datadog monitoring to the retail store sample application, focusing on the ECS deployment option.

## Overview

The retail store sample application consists of multiple microservices deployed on ECS Fargate. To monitor these services with Datadog, we need to:

1. Store the Datadog API key securely
2. Add the Datadog Agent as a sidecar container to each service
3. Configure the application containers to send metrics, logs, and traces to Datadog
4. Update IAM permissions to allow access to the Datadog API key

## Implementation Steps

### 1. Store Datadog API Key in AWS Secrets Manager

First, create a secure storage for your Datadog API key:

```terraform
# Create a new module in terraform/lib/datadog/main.tf
resource "aws_secretsmanager_secret" "datadog_api_key" {
  name        = "${var.environment_name}-datadog-api-key"
  description = "Datadog API key for ${var.environment_name} environment"
}

resource "aws_secretsmanager_secret_version" "datadog_api_key" {
  secret_id     = aws_secretsmanager_secret.datadog_api_key.id
  secret_string = var.datadog_api_key
}

output "datadog_api_key_arn" {
  value = aws_secretsmanager_secret.datadog_api_key.arn
}
```

### 2. Update ECS Service Module to Support Datadog

Modify the ECS service module to include Datadog configuration:

```terraform
# Add to terraform/lib/ecs/service/variables.tf
variable "enable_datadog" {
  description = "Enable Datadog integration"
  type        = bool
  default     = false
}

variable "datadog_api_key_arn" {
  description = "ARN of the Datadog API key secret"
  type        = string
  default     = ""
}
```

### 3. Add Datadog Agent as a Sidecar Container

Update the ECS task definition to include the Datadog Agent container:

```terraform
# Modify terraform/lib/ecs/service/ecs.tf
locals {
  # Existing locals...
  
  # Add Datadog container definition if enabled
  datadog_container = var.enable_datadog ? [{
    name      = "datadog-agent"
    image     = "public.ecr.aws/datadog/agent:latest"
    essential = true
    
    environment = [
      { name = "DD_APM_ENABLED", value = "true" },
      { name = "DD_APM_NON_LOCAL_TRAFFIC", value = "true" },
      { name = "DD_LOGS_ENABLED", value = "true" },
      { name = "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL", value = "true" },
      { name = "DD_PROCESS_AGENT_ENABLED", value = "true" },
      { name = "ECS_FARGATE", value = "true" },
      { name = "DD_ENV", value = var.environment_name },
      { name = "DD_SERVICE", value = var.service_name },
      { name = "DD_TAGS", value = "env:${var.environment_name} service:${var.service_name}" }
    ]
    
    secrets = [
      { name = "DD_API_KEY", valueFrom = var.datadog_api_key_arn }
    ]
    
    portMappings = [
      { containerPort = 8126, hostPort = 8126, protocol = "tcp" }
    ]
    
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group"         = var.cloudwatch_logs_group_id
        "awslogs-region"        = data.aws_region.current.name
        "awslogs-stream-prefix" = "${var.service_name}-datadog-agent"
      }
    }
  }] : []
}

resource "aws_ecs_task_definition" "this" {
  # Existing configuration...
  
  container_definitions = jsonencode(concat([{
    name = "application"
    # Existing application container configuration...
    
    # Add Datadog environment variables if enabled
    environment = concat(
      local.environment_variables,
      var.enable_datadog ? [
        { name = "DD_AGENT_HOST", value = "localhost" },
        { name = "DD_TRACE_AGENT_PORT", value = "8126" },
        { name = "DD_SERVICE_NAME", value = var.service_name },
        { name = "DD_ENV", value = var.environment_name },
        { name = "DD_LOGS_INJECTION", value = "true" }
      ] : []
    )
    
    # Add dependency on Datadog agent if enabled
    dependsOn = var.enable_datadog ? [{ containerName = "datadog-agent", condition = "START" }] : []
  }], local.datadog_container))
}
```

### 4. Update Main ECS Module

Update the main ECS module to pass Datadog configuration:

```terraform
# Add to terraform/lib/ecs/variables.tf
variable "enable_datadog" {
  description = "Enable Datadog integration"
  type        = bool
  default     = false
}

variable "datadog_api_key_arn" {
  description = "ARN of the Datadog API key secret"
  type        = string
  default     = ""
}
```

### 5. Update Service Definitions

For each service (UI, Catalog, Cart, Orders, Checkout), update the service definition to pass the Datadog configuration:

```terraform
# Example for UI service in terraform/lib/ecs/ui.tf
module "ui" {
  source = "./service"
  
  # Existing configuration...
  
  enable_datadog     = var.enable_datadog
  datadog_api_key_arn = var.datadog_api_key_arn
}
```

### 6. Update ECS Default Module

Update the ECS default module to accept Datadog configuration:

```terraform
# Add to terraform/ecs/default/variables.tf
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
```

```terraform
# Add to terraform/ecs/default/main.tf
module "datadog" {
  count  = var.enable_datadog ? 1 : 0
  source = "../../lib/datadog"
  
  environment_name = var.environment_name
  datadog_api_key  = var.datadog_api_key
  tags             = module.tags.result
}

module "retail_app_ecs" {
  # Existing configuration...
  
  enable_datadog     = var.enable_datadog
  datadog_api_key_arn = var.enable_datadog ? module.datadog[0].datadog_api_key_arn : ""
}
```

## Language-Specific Instrumentation

### Java Services (UI, Cart, Orders)

For Java services, add the Datadog Java agent:

1. Update the Dockerfile to download the Datadog Java agent:

```dockerfile
# Add to the Java service Dockerfiles
RUN curl -Lo /app/dd-java-agent.jar https://dtdg.co/latest-java-tracer
```

2. Update the ENTRYPOINT to use the agent:

```dockerfile
ENTRYPOINT ["sh", "-c", "java $JAVA_OPTS -javaagent:/app/dd-java-agent.jar -jar /app/app.jar"]
```

### Go Service (Catalog)

For the Go service, add the Datadog Go client library:

1. Add the Datadog Go client to the Go module:

```bash
go get github.com/DataDog/dd-trace-go/v2/ddtrace/tracer
```

2. Initialize the tracer in the main function:

```go
import "github.com/DataDog/dd-trace-go/v2/ddtrace/tracer"

func main() {
    // Initialize the tracer
    tracer.Start(
        tracer.WithServiceName("catalog"),
        tracer.WithEnv(os.Getenv("DD_ENV")),
    )
    defer tracer.Stop()
    
    // Rest of the application code
}
```

### Node.js Service (Checkout)

For the Node.js service, add the Datadog Node.js client:

1. Add the Datadog Node.js client to the package.json:

```bash
npm install --save dd-trace
```

2. Initialize the tracer at the entry point of the application:

```javascript
// Add at the top of the main file
const tracer = require('dd-trace').init({
  service: 'checkout',
  env: process.env.DD_ENV
});
```

## Usage

To deploy the application with Datadog enabled:

```bash
terraform apply -var="enable_datadog=true" -var="datadog_api_key=YOUR_DATADOG_API_KEY"
```

## Verification

After deployment, verify that:

1. The Datadog Agent containers are running alongside your application containers
2. Metrics, logs, and traces are appearing in your Datadog dashboard
3. Service maps are correctly showing the relationships between services

## Troubleshooting

If you encounter issues:

1. Check the Datadog Agent logs for connection problems
2. Verify that the API key is correctly stored and accessible
3. Ensure that the application containers can communicate with the Datadog Agent on localhost:8126
4. Check that the language-specific instrumentation is correctly configured

## Implementation Details

The following sections provide details about the actual implementation that has been added to the repository.

### Datadog Module

A new Terraform module has been created in `terraform/lib/datadog/` to handle the Datadog API key storage:

```terraform
# terraform/lib/datadog/main.tf
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
```

### ECS Service Module Updates

The ECS service module has been updated to support Datadog integration:

1. Added variables for Datadog configuration:

```terraform
# terraform/lib/ecs/service/variables.tf
variable "enable_datadog" {
  description = "Enable Datadog integration"
  type        = bool
  default     = false
}

variable "datadog_api_key_arn" {
  description = "ARN of the Datadog API key secret"
  type        = string
  default     = ""
}
```

2. Created a separate file for Datadog sidecar configuration:

```terraform
# terraform/lib/ecs/service/datadog-sidecar.tf
locals {
  # Only add Datadog sidecar if enabled
  datadog_container_definition = var.enable_datadog ? jsonencode([{
    "name": "datadog-agent",
    "image": "public.ecr.aws/datadog/agent:latest",
    "essential": true,
    "environment": [
      {
        "name": "DD_APM_ENABLED",
        "value": "true"
      },
      {
        "name": "DD_APM_NON_LOCAL_TRAFFIC",
        "value": "true"
      },
      {
        "name": "DD_LOGS_ENABLED",
        "value": "true"
      },
      {
        "name": "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL",
        "value": "true"
      },
      {
        "name": "DD_PROCESS_AGENT_ENABLED",
        "value": "true"
      },
      {
        "name": "DD_DOCKER_LABELS_AS_TAGS",
        "value": "{\"com.amazonaws.ecs.task-definition-family\":\"service_name\"}"
      },
      {
        "name": "DD_TAGS",
        "value": "env:${var.environment_name} service:${var.service_name}"
      },
      {
        "name": "ECS_FARGATE",
        "value": "true"
      }
    ],
    "secrets": [
      {
        "name": "DD_API_KEY",
        "valueFrom": var.datadog_api_key_arn
      }
    ],
    "logConfiguration": {
      "logDriver": "awslogs",
      "options": {
        "awslogs-group": "${var.cloudwatch_logs_group_id}",
        "awslogs-region": "${data.aws_region.current.name}",
        "awslogs-stream-prefix": "${var.service_name}-datadog-agent"
      }
    },
    "portMappings": [
      {
        "containerPort": 8126,
        "hostPort": 8126,
        "protocol": "tcp"
      }
    ]
  }]) : "[]"

  # Add Datadog environment variables to application container if enabled
  datadog_app_environment = var.enable_datadog ? [
    {
      "name": "DD_AGENT_HOST",
      "value": "localhost"
    },
    {
      "name": "DD_TRACE_AGENT_PORT",
      "value": "8126"
    },
    {
      "name": "DD_SERVICE_NAME",
      "value": "${var.service_name}"
    },
    {
      "name": "DD_ENV",
      "value": "${var.environment_name}"
    },
    {
      "name": "DD_LOGS_INJECTION",
      "value": "true"
    },
    {
      "name": "DD_PROFILING_ENABLED",
      "value": "true"
    }
  ] : []
}
```

3. Updated the ECS task definition to include the Datadog Agent:

```terraform
# terraform/lib/ecs/service/ecs.tf
resource "aws_ecs_task_definition" "this" {
  # ...existing configuration...
  
  container_definitions = <<DEFINITION
    [
      {
        "name": "application",
        "image": "${var.container_image}",
        # ...existing configuration...
        "dependsOn": ${var.enable_datadog ? "[{\"containerName\": \"datadog-agent\", \"condition\": \"START\"}]" : "[]"}
      }
      ${var.enable_datadog ? ",${substr(local.datadog_container, 1, length(local.datadog_container) - 2)}" : ""}
    ]
  DEFINITION
  
  # ...rest of configuration...
}
```

### ECS Default Module Updates

The ECS default module has been updated to support Datadog integration:

1. Added variables for Datadog configuration:

```terraform
# terraform/ecs/default/variables.tf
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
```

2. Added the Datadog module instantiation:

```terraform
# terraform/ecs/default/main.tf
module "datadog" {
  count  = var.enable_datadog ? 1 : 0
  source = "../../lib/datadog"
  
  environment_name = var.environment_name
  datadog_api_key  = var.datadog_api_key
  tags             = module.tags.result
}
```

3. Updated the retail app ECS module to pass Datadog configuration:

```terraform
# terraform/ecs/default/main.tf
module "retail_app_ecs" {
  # ...existing configuration...
  
  # Datadog configuration
  enable_datadog     = var.enable_datadog
  datadog_api_key_arn = var.enable_datadog ? module.datadog[0].datadog_api_key_arn : ""
}
```

With these changes, the retail store sample application can now be deployed with Datadog monitoring enabled by setting the `enable_datadog` and `datadog_api_key` variables.
