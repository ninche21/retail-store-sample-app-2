module "tags" {
  source = "../../lib/tags"

  environment_name = local.standard_environment_name
}

module "vpc" {
  source = "../../lib/vpc"

  environment_name = local.standard_environment_name

  tags = module.tags.result
}

module "datadog" {
  count  = var.enable_datadog ? 1 : 0
  source = "../../lib/datadog"
  
  environment_name = local.standard_environment_name
  datadog_api_key  = var.datadog_api_key
  tags             = module.tags.result
  
  # Datadog integration role and forwarder configuration
  datadog_integration_role_name = var.datadog_integration_role_name
  datadog_forwarder_lambda_arn  = var.datadog_forwarder_lambda_arn
  
  # Database monitoring configuration
  enable_database_monitoring = var.enable_database_monitoring
  vpc_id                     = module.vpc.inner.vpc_id
  subnet_ids                 = module.vpc.inner.private_subnets
  ecs_cluster_arn            = module.retail_app_ecs.cluster_arn
  
  # Catalog database configuration
  catalog_db_endpoint        = module.dependencies.catalog_db_endpoint
  catalog_db_port            = module.dependencies.catalog_db_port
  catalog_db_name            = module.dependencies.catalog_db_database_name
  catalog_db_username        = module.dependencies.catalog_db_master_username
  catalog_db_password        = module.dependencies.catalog_db_master_password
  catalog_security_group_id  = module.dependencies.catalog_db_security_group_id
  
  # Orders database configuration
  orders_db_endpoint         = module.dependencies.orders_db_endpoint
  orders_db_port             = module.dependencies.orders_db_port
  orders_db_name             = module.dependencies.orders_db_database_name
  orders_db_username         = module.dependencies.orders_db_master_username
  orders_db_password         = module.dependencies.orders_db_master_password
  orders_security_group_id   = module.dependencies.orders_db_security_group_id
}

module "dependencies" {
  source = "../../lib/dependencies"

  environment_name = local.standard_environment_name
  tags             = module.tags.result

  vpc_id     = module.vpc.inner.vpc_id
  subnet_ids = module.vpc.inner.private_subnets

  catalog_security_group_id  = module.retail_app_ecs.catalog_security_group_id
  orders_security_group_id   = module.retail_app_ecs.orders_security_group_id
  checkout_security_group_id = module.retail_app_ecs.checkout_security_group_id
}

module "retail_app_ecs" {
  source = "../../lib/ecs"

  environment_name          = local.standard_environment_name
  vpc_id                    = module.vpc.inner.vpc_id
  subnet_ids                = module.vpc.inner.private_subnets
  public_subnet_ids         = module.vpc.inner.public_subnets
  tags                      = module.tags.result
  container_image_overrides = var.container_image_overrides

  catalog_db_endpoint = module.dependencies.catalog_db_endpoint
  catalog_db_port     = module.dependencies.catalog_db_port
  catalog_db_name     = module.dependencies.catalog_db_database_name
  catalog_db_username = module.dependencies.catalog_db_master_username
  catalog_db_password = module.dependencies.catalog_db_master_password

  carts_dynamodb_table_name = module.dependencies.carts_dynamodb_table_name
  carts_dynamodb_policy_arn = module.dependencies.carts_dynamodb_policy_arn

  checkout_redis_endpoint = module.dependencies.checkout_elasticache_primary_endpoint
  checkout_redis_port     = module.dependencies.checkout_elasticache_port

  orders_db_endpoint = module.dependencies.orders_db_endpoint
  orders_db_port     = module.dependencies.orders_db_port
  orders_db_name     = module.dependencies.orders_db_database_name
  orders_db_username = module.dependencies.orders_db_master_username
  orders_db_password = module.dependencies.orders_db_master_password

  mq_endpoint = module.dependencies.mq_broker_endpoint
  mq_username = module.dependencies.mq_user
  mq_password = module.dependencies.mq_password
  
  # Datadog configuration
  enable_datadog           = var.enable_datadog
  datadog_api_key_arn      = var.enable_datadog ? module.datadog[0].datadog_api_key_arn : ""
  datadog_forwarder_lambda_arn = var.datadog_forwarder_lambda_arn
}
