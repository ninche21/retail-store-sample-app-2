locals {
  # Only add Datadog sidecar if enabled
  datadog_container_definition = var.enable_datadog ? jsonencode([{
    "name": "datadog-agent",
    "image": "public.ecr.aws/datadog/agent:7",  # Using a specific version instead of latest
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
      },
      {
        "name": "DD_SITE",
        "value": "datadoghq.com"
      },
      {
        "name": "DD_ENV",
        "value": "${var.environment_name}"
      },
      {
        "name": "DD_SERVICE",
        "value": "${var.service_name}"
      },
      {
        "name": "DD_VERSION",
        "value": "1.1.0"
      },
      {
        "name": "DD_APM_DD_URL",
        "value": "https://trace.agent.datadoghq.com"
      },
      {
        "name": "DD_LOGS_CONFIG_USE_HTTP",
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
