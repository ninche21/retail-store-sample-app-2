# Create a dedicated ECS cluster for Datadog Database Monitoring
resource "aws_ecs_cluster" "datadog_dbm" {
  count = var.enable_database_monitoring ? 1 : 0
  name  = var.datadog_dbm_cluster_name

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = module.tags.result
}

# Output the Datadog DBM cluster ARN
output "datadog_dbm_cluster_arn" {
  description = "ARN of the Datadog DBM ECS cluster"
  value       = var.enable_database_monitoring ? aws_ecs_cluster.datadog_dbm[0].arn : ""
}

# Output the Datadog DBM cluster name
output "datadog_dbm_cluster_name" {
  description = "Name of the Datadog DBM ECS cluster"
  value       = var.enable_database_monitoring ? aws_ecs_cluster.datadog_dbm[0].name : ""
}

# Update the Datadog module configuration to use the dedicated DBM cluster
locals {
  datadog_dbm_config = {
    ecs_cluster_arn = var.enable_database_monitoring ? aws_ecs_cluster.datadog_dbm[0].arn : ""
  }
}
