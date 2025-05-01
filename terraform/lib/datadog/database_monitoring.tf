variable "enable_database_monitoring" {
  description = "Enable Datadog database monitoring"
  type        = bool
  default     = false
}

variable "catalog_db_endpoint" {
  description = "Endpoint of the catalog database"
  type        = string
  default     = ""
}

variable "catalog_db_port" {
  description = "Port of the catalog database"
  type        = number
  default     = 3306
}

variable "catalog_db_name" {
  description = "Name of the catalog database"
  type        = string
  default     = "catalog"
}

variable "catalog_db_username" {
  description = "Username for the catalog database"
  type        = string
  default     = ""
}

variable "catalog_db_password" {
  description = "Password for the catalog database"
  type        = string
  default     = ""
  sensitive   = true
}

variable "orders_db_endpoint" {
  description = "Endpoint of the orders database"
  type        = string
  default     = ""
}

variable "orders_db_port" {
  description = "Port of the orders database"
  type        = number
  default     = 5432
}

variable "orders_db_name" {
  description = "Name of the orders database"
  type        = string
  default     = "orders"
}

variable "orders_db_username" {
  description = "Username for the orders database"
  type        = string
  default     = ""
}

variable "orders_db_password" {
  description = "Password for the orders database"
  type        = string
  default     = ""
  sensitive   = true
}

variable "ecs_cluster_arn" {
  description = "ARN of the ECS cluster to use for database monitoring"
  type        = string
  default     = ""
}

variable "subnet_ids" {
  description = "Subnet IDs to use for database monitoring tasks"
  type        = list(string)
  default     = []
}

# Create IAM role for Datadog database monitoring
resource "aws_iam_role" "datadog_dbm_role" {
  count = var.enable_database_monitoring ? 1 : 0
  name  = "${var.environment_name}-datadog-dbm-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Create IAM policy for Datadog database monitoring
resource "aws_iam_policy" "datadog_dbm_policy" {
  count       = var.enable_database_monitoring ? 1 : 0
  name        = "${var.environment_name}-datadog-dbm-policy"
  description = "Policy for Datadog database monitoring"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "rds:DescribeDBInstances",
          "rds:DescribeDBClusters",
          "rds:ListTagsForResource",
          "cloudwatch:GetMetricData",
          "cloudwatch:GetMetricStatistics",
          "cloudwatch:ListMetrics"
        ]
        Effect   = "Allow"
        Resource = "*"
      }
    ]
  })
}

# Attach policy to role
resource "aws_iam_role_policy_attachment" "datadog_dbm_policy_attachment" {
  count      = var.enable_database_monitoring ? 1 : 0
  role       = aws_iam_role.datadog_dbm_role[0].name
  policy_arn = aws_iam_policy.datadog_dbm_policy[0].arn
}

# Create security group for Datadog database monitoring
resource "aws_security_group" "datadog_dbm_sg" {
  count       = var.enable_database_monitoring ? 1 : 0
  name        = "${var.environment_name}-datadog-dbm-sg"
  description = "Security group for Datadog database monitoring"
  vpc_id      = var.vpc_id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.environment_name}-datadog-dbm-sg"
  })
}

# Create task definition for catalog database monitoring
resource "aws_ecs_task_definition" "datadog_catalog_dbm" {
  count                    = var.enable_database_monitoring && var.catalog_db_endpoint != "" ? 1 : 0
  family                   = "${var.environment_name}-datadog-catalog-dbm"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.datadog_dbm_role[0].arn
  task_role_arn            = aws_iam_role.datadog_dbm_role[0].arn

  container_definitions = jsonencode([
    {
      name      = "datadog-agent"
      image     = "public.ecr.aws/datadog/agent:7"
      essential = true
      environment = [
        {
          name  = "DD_API_KEY"
          value = var.datadog_api_key
        },
        {
          name  = "DD_SITE"
          value = "datadoghq.com"
        },
        {
          name  = "DD_DBM_ENABLED"
          value = "true"
        },
        {
          name  = "DD_APM_ENABLED"
          value = "false"
        },
        {
          name  = "ECS_FARGATE"
          value = "true"
        },
        {
          name  = "DD_ENV"
          value = var.environment_name
        },
        {
          name  = "DD_SERVICE"
          value = "catalog-db-monitoring"
        },
        {
          name  = "DD_DBM_MYSQL_HOST"
          value = var.catalog_db_endpoint
        },
        {
          name  = "DD_DBM_MYSQL_PORT"
          value = tostring(var.catalog_db_port)
        },
        {
          name  = "DD_DBM_MYSQL_USERNAME"
          value = var.catalog_db_username
        },
        {
          name  = "DD_DBM_MYSQL_PASSWORD"
          value = var.catalog_db_password
        },
        {
          name  = "DD_DBM_MYSQL_DATABASE"
          value = var.catalog_db_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment_name}-datadog-dbm"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "catalog"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  tags = var.tags
}

# Create task definition for orders database monitoring
resource "aws_ecs_task_definition" "datadog_orders_dbm" {
  count                    = var.enable_database_monitoring && var.orders_db_endpoint != "" ? 1 : 0
  family                   = "${var.environment_name}-datadog-orders-dbm"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = aws_iam_role.datadog_dbm_role[0].arn
  task_role_arn            = aws_iam_role.datadog_dbm_role[0].arn

  container_definitions = jsonencode([
    {
      name      = "datadog-agent"
      image     = "public.ecr.aws/datadog/agent:7"
      essential = true
      environment = [
        {
          name  = "DD_API_KEY"
          value = var.datadog_api_key
        },
        {
          name  = "DD_SITE"
          value = "datadoghq.com"
        },
        {
          name  = "DD_DBM_ENABLED"
          value = "true"
        },
        {
          name  = "DD_APM_ENABLED"
          value = "false"
        },
        {
          name  = "ECS_FARGATE"
          value = "true"
        },
        {
          name  = "DD_ENV"
          value = var.environment_name
        },
        {
          name  = "DD_SERVICE"
          value = "orders-db-monitoring"
        },
        {
          name  = "DD_DBM_POSTGRES_HOST"
          value = var.orders_db_endpoint
        },
        {
          name  = "DD_DBM_POSTGRES_PORT"
          value = tostring(var.orders_db_port)
        },
        {
          name  = "DD_DBM_POSTGRES_USERNAME"
          value = var.orders_db_username
        },
        {
          name  = "DD_DBM_POSTGRES_PASSWORD"
          value = var.orders_db_password
        },
        {
          name  = "DD_DBM_POSTGRES_DATABASE"
          value = var.orders_db_name
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          "awslogs-group"         = "/ecs/${var.environment_name}-datadog-dbm"
          "awslogs-region"        = data.aws_region.current.name
          "awslogs-stream-prefix" = "orders"
          "awslogs-create-group"  = "true"
        }
      }
    }
  ])

  tags = var.tags
}

# Create ECS service for catalog database monitoring
resource "aws_ecs_service" "datadog_catalog_dbm" {
  count           = var.enable_database_monitoring && var.catalog_db_endpoint != "" ? 1 : 0
  name            = "datadog-catalog-dbm"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.datadog_catalog_dbm[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.datadog_dbm_sg[0].id]
    assign_public_ip = false
  }

  tags = var.tags
}

# Create ECS service for orders database monitoring
resource "aws_ecs_service" "datadog_orders_dbm" {
  count           = var.enable_database_monitoring && var.orders_db_endpoint != "" ? 1 : 0
  name            = "datadog-orders-dbm"
  cluster         = var.ecs_cluster_arn
  task_definition = aws_ecs_task_definition.datadog_orders_dbm[0].arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = var.subnet_ids
    security_groups  = [aws_security_group.datadog_dbm_sg[0].id]
    assign_public_ip = false
  }

  tags = var.tags
}

# Create security group rules to allow access to databases
resource "aws_security_group_rule" "catalog_db_access" {
  count                    = var.enable_database_monitoring ? 1 : 0
  type                     = "ingress"
  from_port                = var.catalog_db_port
  to_port                  = var.catalog_db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.datadog_dbm_sg[0].id
  security_group_id        = var.catalog_security_group_id
  description              = "Allow Datadog monitoring agent to access catalog database"
}

resource "aws_security_group_rule" "orders_db_access" {
  count                    = var.enable_database_monitoring ? 1 : 0
  type                     = "ingress"
  from_port                = var.orders_db_port
  to_port                  = var.orders_db_port
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.datadog_dbm_sg[0].id
  security_group_id        = var.orders_security_group_id
  description              = "Allow Datadog monitoring agent to access orders database"
}

# Add data source for current region
data "aws_region" "current" {}
