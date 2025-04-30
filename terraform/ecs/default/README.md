# AWS Containers Retail Sample - ECS Terraform (Default)

This Terraform module creates all the necessary infrastructure and deploys the retail sample application on [Amazon Elastic Container Service](https://aws.amazon.com/ecs/).

It provides:

- VPC with public and private subnets
- ECS cluster using Fargate for compute
- All application dependencies such as RDS, DynamoDB table, Elasticache etc.
- Deployment of application components as ECS services
- ECS Service Connect to handle traffic between services
- Integration with Datadog for monitoring and observability

NOTE: This will create resources in your AWS account which will incur costs. You are responsible for these costs, and should understand the resources being created before proceeding.

## Usage

Pre-requisites for this are:

- AWS, Terraform and kubectl installed locally
- AWS CLI configured and authenticated with account to deploy to

After cloning this repository run the following commands:

```shell
cd terraform/ecs/default

terraform init
terraform plan
terraform apply
```

The final command will prompt for confirmation that you wish to create the specified resources. After confirming the process will take at least 15 minutes to complete. You can then retrieve the HTTP endpoint for the UI from Terraform outputs:

```shell
terraform output -raw application_url
```

Enter the URL in a web browser to access the application.

## Datadog Integration

This module supports integration with Datadog for monitoring and observability. To enable Datadog integration:

1. Set `enable_datadog = true` in your terraform.tfvars file
2. Provide your Datadog API key as `datadog_api_key = "your-api-key"`
3. Ensure the Datadog AWS integration is installed in your AWS account
4. Specify the Datadog integration role name (default is "DatadogIntegrationRole")
5. Provide the ARN of the Datadog Forwarder Lambda function as `datadog_forwarder_lambda_arn`

### Datadog AWS Integration Setup

For the Datadog AWS integration to work properly, you need to:

1. Install the Datadog AWS integration in your Datadog account
2. Create a Datadog integration IAM role in your AWS account
3. Deploy the Datadog Forwarder Lambda function
4. Configure CloudWatch logs to forward to Datadog

The Terraform code will:
- Attach the CloudWatchLogsReadOnlyAccess policy to the Datadog integration role
- Create a subscription filter to forward ECS logs to the Datadog Forwarder Lambda
- Add the necessary Lambda permissions for CloudWatch Logs to invoke the Forwarder

After deployment, verify in your Datadog account that:
- Log collection is enabled for your AWS account
- The log groups pattern includes your ECS log groups (e.g., `retail-store-ecs*`)
- The correct AWS account and regions are selected

## Reference

This section documents the variables and outputs of the Terraform configuration.

### Inputs

| Name                        | Description                                                          | Type     | Default                    | Required |
| --------------------------- | -------------------------------------------------------------------- | -------- | -------------------------- | :------: |
| `environment_name`          | Name of the environment which will be used for all resources created | `string` | `retail-store-ecs`         |    no    |
| `enable_datadog`            | Enable Datadog integration                                           | `bool`   | `false`                    |    no    |
| `datadog_api_key`           | Datadog API key                                                      | `string` | `""`                       |    no    |
| `datadog_integration_role_name` | Name of the Datadog integration IAM role                         | `string` | `"DatadogIntegrationRole"` |    no    |
| `datadog_forwarder_lambda_arn` | ARN of the Datadog Forwarder Lambda function                      | `string` | -                          |   yes*   |

*Required when `enable_datadog` is set to `true`

### Outputs

| Name              | Description                               |
| ----------------- | ----------------------------------------- |
| `application_url` | URL where the application can be accessed |
