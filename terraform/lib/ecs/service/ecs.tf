locals {
  #adding this validation block for it to check for API Key 
  validate_datadog_config = var.enable_datadog && var.datadog_api_key_arn == "" ? tobool("Datadog API key ARN must be provided when Datadog is enabled") : true

  environment = jsonencode([for k, v in var.environment_variables : {
    "name" : k,
    "value" : v
  }])

  secrets = jsonencode([for k, v in var.secrets : {
    "name" : k,
    "valueFrom" : v
  }])
  
  # Add Datadog environment variables if enabled
  datadog_env_vars = var.enable_datadog ? jsonencode([
    {
      "name": "DD_AGENT_HOST",
      "value": "*********"
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
  ]) : "[]"
  # FireLens container definition
  firelens_container = {
    essential = true
    image = "amazon/aws-for-fluent-bit:stable"
    name = "log_router"
    firelensConfiguration = {
      type = "fluentbit"
      options = {
        "enable-ecs-log-metadata" = "true"
      }
    }
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        "awslogs-group" = var.cloudwatch_logs_group_id
        "awslogs-region" = data.aws_region.current.name
        "awslogs-stream-prefix" = "firelens"
      }
    }
    memoryReservation = 50
  }
}

data "aws_region" "current" {}

resource "aws_ecs_task_definition" "this" {
  family                   = "${var.environment_name}-${var.service_name}"
  container_definitions    = jsonencode([
    {
      name                 = "application"
      image                = var.container_image
      essential            = true
      portMappings         = [
        {
          containerPort    = 8080
          hostPort         = 8080
          protocol         = "tcp"
          name             = "application"
        }
      ]
      environment          = jsondecode(local.environment)
      secrets              = jsondecode(local.secrets)
      cpu                  = 0
      mountPoints          = []
      volumesFrom          = []
      healthCheck          = {
        command           = [ "CMD-SHELL", "curl -f http://localhost:8080${var.healthcheck_path} || exit 1" ]
        interval          = 10
        startPeriod       = 60
        retries           = 3
        timeout           = 5
      }
      logConfiguration     = {
        logDriver          = "awsfirelens"
        options            = {
          Name             = "datadog"
          Host             = "http-intake.logs.datadoghq.com"
          TLS              = "on"
          dd_service       = var.service_name
          dd_source        = "ecs"
          dd_tags          = "env:${var.environment_name},service:${var.service_name}"
          provider         = "ecs"
        }
        secretOptions      = [
          {
            name           = "apikey"
            valueFrom      = var.datadog_api_key_arn
          }
        ]
      }
      dependsOn            = var.enable_datadog ? [
        {
          containerName    = "datadog-agent"
          condition        = "START"
        },
        {
          containerName    = "log_router"
          condition        = "START"
        }
      ] : [
        {
          containerName    = "log_router"
          condition        = "START"
        }
      ]
    },
    local.firelens_container,
    var.enable_datadog ? {
      name                = "datadog-agent"
      image               = "public.ecr.aws/datadog/agent:latest"
      essential           = true
      environment         = [
        { name = "DD_SITE", value = "datadoghq.com" },
        { name = "DD_ECS_FARGATE", value = "true" },
        { name = "DD_APM_ENABLED", value = "true" },
        { name = "DD_APM_NON_LOCAL_TRAFFIC", value = "true" },
        { name = "DD_LOGS_ENABLED", value = "true" },
        { name = "DD_LOGS_CONFIG_CONTAINER_COLLECT_ALL", value = "true" },
        { name = "DD_AC_EXCLUDE", value = "name:datadog-agent" },
        { name = "DD_TAGS", value = "env:${var.environment_name} service:${var.service_name}" },
        { name = "DD_ECS_TASK_COLLECTION_ENABLED", value = "true" },
        { name = "DD_PROCESS_AGENT_ENABLED", value = "true" }
      ]
      secrets             = [
        { name = "DD_API_KEY", valueFrom = var.datadog_api_key_arn }
      ]
      logConfiguration    = {
        logDriver         = "awslogs"
        options           = {
          awslogs-group   = var.cloudwatch_logs_group_id
          awslogs-region  = data.aws_region.current.name
          awslogs-stream-prefix = "${var.service_name}-datadog-agent"
        }
      }
      portMappings        = [
        {
          containerPort   = 8126
          hostPort       = 8126
          protocol      = "tcp"
        }
      ]
    } : null
  ])
  requires_compatibilities = ["FARGATE"]
  network_mode            = "awsvpc"
  cpu                     = "1024"
  memory                  = "2048"
  execution_role_arn      = aws_iam_role.task_execution_role.arn
  task_role_arn           = aws_iam_role.task_role.arn
}

resource "aws_ecs_service" "this" {
  name                   = var.service_name
  cluster                = var.cluster_arn
  task_definition        = aws_ecs_task_definition.this.arn
  desired_count          = 1
  
  timeouts {
    create = "40m"
  }
  launch_type            = "FARGATE"
  enable_execute_command = true
  wait_for_steady_state  = true

  network_configuration {
    security_groups  = [aws_security_group.this.id]
    subnets          = var.subnet_ids
    assign_public_ip = false
  }

  service_connect_configuration {
    enabled   = true
    namespace = var.service_discovery_namespace_arn
    service {
      client_alias {
        dns_name = var.service_name
        port     = "80"
      }
      discovery_name = var.service_name
      port_name      = "application"
    }
  }

  dynamic "load_balancer" {
    for_each = var.alb_target_group_arn == "" ? [] : [1]

    content {
      target_group_arn = var.alb_target_group_arn
      container_name   = "application"
      container_port   = 8080
    }
  }

  tags = var.tags
}
