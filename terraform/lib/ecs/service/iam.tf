resource "aws_iam_role" "task_execution_role" {
  name               = "${var.environment_name}-${var.service_name}-te"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# Create a policy to allow access to Secrets Manager
resource "aws_iam_policy" "secrets_manager_access" {
  name        = "${var.environment_name}-${var.service_name}-secrets-access"
  path        = "/"
  description = "Policy to allow access to Secrets Manager for Datadog API key"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue"
        ]
        Resource = [
          "*"  # Allow access to all secrets for now to simplify deployment
        ]
      }
    ]
  })
}

# Create a policy for CloudWatch Logs access
resource "aws_iam_policy" "cloudwatch_logs_access" {
  name        = "${var.environment_name}-${var.service_name}-cloudwatch-logs-access"
  path        = "/"
  description = "Policy to allow access to CloudWatch Logs for FireLens"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogStream",
          "logs:PutLogEvents",
          "logs:CreateLogGroup"
        ]
        Resource = "arn:aws:logs:*:*:*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "task_execution_role_policy" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# Attach the Secrets Manager access policy to the task execution role
resource "aws_iam_role_policy_attachment" "secrets_manager_access" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.secrets_manager_access.arn
}

# Attach the CloudWatch Logs access policy to the task execution role
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_access" {
  role       = aws_iam_role.task_execution_role.name
  policy_arn = aws_iam_policy.cloudwatch_logs_access.arn
}

resource "aws_iam_role_policy_attachment" "task_execution_role_additional" {
  count = length(var.additional_task_execution_role_iam_policy_arns)

  role       = aws_iam_role.task_execution_role.name
  policy_arn = var.additional_task_execution_role_iam_policy_arns[count.index]
}

resource "aws_iam_role" "task_role" {
  name               = "${var.environment_name}-${var.service_name}-task"
  assume_role_policy = data.aws_iam_policy_document.assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "task_role_additional" {
  count = length(var.additional_task_role_iam_policy_arns)

  role       = aws_iam_role.task_role.name
  policy_arn = var.additional_task_role_iam_policy_arns[count.index]
}

resource "aws_iam_role_policy_attachment" "task_role_policy" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.ecs_exec.arn
}

resource "aws_iam_policy" "ecs_exec" {
  name        = "${var.environment_name}-${var.service_name}-exec"
  path        = "/"
  description = "ECS exec policy"

  policy = <<EOF
{
   "Version": "2012-10-17",
   "Statement": [
       {
       "Effect": "Allow",
       "Action": [
            "ssmmessages:CreateControlChannel",
            "ssmmessages:CreateDataChannel",
            "ssmmessages:OpenControlChannel",
            "ssmmessages:OpenDataChannel"
       ],
      "Resource": "*"
      }
   ]
}
EOF
}

# Add a policy for Datadog Agent permissions
resource "aws_iam_policy" "datadog_agent" {
  name        = "${var.environment_name}-${var.service_name}-datadog-agent"
  path        = "/"
  description = "IAM policy for Datadog Agent"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecs:ListClusters",
          "ecs:ListContainerInstances",
          "ecs:DescribeContainerInstances"
        ]
        Resource = "*"
      }
    ]
  })
}

# Attach the Datadog Agent policy to the task role
resource "aws_iam_role_policy_attachment" "datadog_agent" {
  role       = aws_iam_role.task_role.name
  policy_arn = aws_iam_policy.datadog_agent.arn
}

    
