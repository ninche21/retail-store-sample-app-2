resource "aws_cloudwatch_log_group" "ecs_tasks" {
  name              = "${var.environment_name}-tasks"
  retention_in_days = 7
  tags              = var.tags
}

# Create a subscription filter to forward logs to Datadog if enabled
resource "aws_cloudwatch_log_subscription_filter" "datadog_forwarder" {
  count           = var.enable_datadog && var.datadog_forwarder_lambda_arn != "" ? 1 : 0
  name            = "DatadogForwarderFilter"
  log_group_name  = aws_cloudwatch_log_group.ecs_tasks.name
  filter_pattern  = ""
  destination_arn = var.datadog_forwarder_lambda_arn
}

# Add permission for CloudWatch Logs to invoke the Datadog Forwarder Lambda
resource "aws_lambda_permission" "cloudwatch_logs_to_datadog" {
  count         = var.enable_datadog && var.datadog_forwarder_lambda_arn != "" ? 1 : 0
  statement_id  = "${replace(var.environment_name, "-", "")}ECSLogs"
  action        = "lambda:InvokeFunction"
  function_name = var.datadog_forwarder_lambda_arn
  principal     = "logs.${data.aws_region.current.name}.amazonaws.com"
  source_arn    = "${aws_cloudwatch_log_group.ecs_tasks.arn}:*"
}

data "aws_region" "current" {}
