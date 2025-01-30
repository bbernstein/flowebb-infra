# Flowebb Infrastructure

This repository contains the Terraform configuration for the Flowebb infrastructure. The infrastructure is managed using a modular approach with separate configurations for bootstrapping and production environments.

## Repository Structure

```
terraform/
├── bootstrap/          # Bootstrap configuration for initial AWS setup
├── environments/
│   └── prod/          # Production environment configuration
├── global/            # Global AWS resources (Route53)
└── modules/           # Reusable Terraform modules
    ├── base_networking/    # VPC, subnets, and core network resources
    ├── compute/           # Lambda functions and API Gateway
    ├── edge_networking/   # CloudFront and DNS configuration
    ├── github_actions/    # GitHub Actions IAM roles and permissions
    ├── iam/              # IAM roles and policies
    ├── lambda_build/     # Lambda build configuration
    └── storage/          # S3 buckets and DynamoDB tables
```

## Prerequisites

- AWS CLI configured with appropriate credentials
- Terraform installed (version 1.0.0 or later)
- Access to the AWS account where infrastructure will be deployed

## Bootstrapping AWS Infrastructure

The bootstrap directory contains the configuration needed to set up the initial AWS infrastructure, including the S3 bucket for storing Terraform state and DynamoDB table for state locking.

To bootstrap the infrastructure:

1. Navigate to the bootstrap directory:
   ```bash
   cd terraform/bootstrap
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Apply the bootstrap configuration:
   ```bash
   terraform apply
   ```

This will create:
- An S3 bucket named `flowebb-terraform-state` for storing Terraform state
- A DynamoDB table named `terraform-state-lock` for state locking
- Both resources are configured with appropriate settings for production use

## Applying Production Infrastructure

The production infrastructure is managed from the `terraform/environments/prod` directory. This configuration uses the state bucket created during bootstrapping.

To apply the production infrastructure:

1. Navigate to the production environment directory:
   ```bash
   cd terraform/environments/prod
   ```

2. Initialize Terraform:
   ```bash
   terraform init
   ```

3. Review the terraform.tfvars file and ensure all variables are set correctly

4. Apply the configuration:
   ```bash
   terraform apply
   ```

## Module Descriptions

### base_networking
- Creates the core network infrastructure including VPC, subnets, and routing
- Manages SSL certificates through ACM
- Sets up Route53 DNS configuration

### compute
- Deploys Lambda functions for the application backend
- Configures API Gateway for REST API endpoints
- Manages CloudWatch logs with 30-day retention
- Integrates with the frontend domain

### edge_networking
- Sets up CloudFront distribution for the frontend
- Configures DNS records for frontend and API domains
- Manages SSL certificate association
- Handles CloudFront logging

### github_actions
- Creates IAM roles for GitHub Actions workflows
- Configures permissions for frontend deployment
- Manages access to S3 buckets and CloudFront
- Sets up permissions for Terraform state management

### iam
- Defines IAM roles and policies for various services
- Manages permissions for DynamoDB access
- Controls access to S3 buckets
- Sets up Lambda execution roles

### lambda_build
- Handles Lambda function build configuration
- Manages build artifacts and dependencies

### storage
- Creates and configures S3 buckets for frontend hosting
- Sets up DynamoDB tables for application data
- Manages CloudFront logging buckets
- Configures bucket policies and access controls

## Making Changes

When making changes to the infrastructure:

1. Identify the appropriate module(s) that need to be modified
2. Update the relevant `.tf` files in the module directory
3. If adding new variables, update the `variables.tf` file and corresponding `terraform.tfvars`
4. Test changes in a development environment if available
5. Apply changes using `terraform plan` and `terraform apply`

## Important Notes

- The state bucket and lock table are configured with prevent_destroy to avoid accidental deletion
- All modules use provider versioning to ensure consistency
- Dependencies between modules are managed using `depends_on` blocks
- The infrastructure supports multiple environments through variable configuration
- CloudWatch logs are retained for 30 days by default
- GitHub Actions integration is configured for specific repositories in the organization

## Troubleshooting

If you encounter state locking issues:
1. Check the DynamoDB table for stuck locks
2. Verify AWS credentials have appropriate permissions
3. Ensure the state bucket is accessible

For deployment issues:
1. Verify all required variables are set in terraform.tfvars
2. Check CloudWatch logs for Lambda function errors
3. Verify GitHub Actions have appropriate permissions
