terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  backend "s3" {
    bucket         = "flowebb-terraform-state-bucket"
    key            = "prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}

output "frontend_deployment_details" {
  value = {
    frontend_bucket_name       = module.storage.frontend_bucket_domain
    cloudfront_distribution_id = module.networking.cloudfront_distribution_id
  }
}

provider "aws" {
  region = var.aws_region
}

provider "aws" {
  alias  = "us-east-1"
  region = "us-east-1"
}

# First create storage resources
module "storage" {
  source = "../../modules/storage"

  project_name    = var.project_name
  environment     = var.environment
  frontend_domain = var.frontend_domain
}

# Then create IAM roles that depend on storage ARNs
module "iam" {
  source = "../../modules/iam"

  project_name            = var.project_name
  environment             = var.environment
  dynamodb_table_arns     = module.storage.dynamodb_table_arns
  station_list_bucket_arn = module.storage.station_list_bucket_arn
}

# Create the API Gateway and Lambda functions
module "compute" {
  source = "../../modules/compute"

  project_name           = var.project_name
  environment            = var.environment
  lambda_role_arn        = module.iam.lambda_role_arn
  station_list_bucket_id = module.storage.station_list_bucket_id
  api_domain             = var.api_domain
  domain_name            = var.domain_name
  frontend_domain        = var.frontend_domain
  log_retention_days     = 30
}

# Finally create DNS and CDN configuration
module "networking" {
  source = "../../modules/networking"

  providers = {
    aws           = aws
    aws.us-east-1 = aws.us-east-1
  }

  project_name    = var.project_name
  environment     = var.environment
  domain_name     = var.domain_name
  frontend_domain = var.frontend_domain
  api_domain = var.api_domain

  # Pass the resources needed for CloudFront
  frontend_bucket_domain = module.storage.frontend_bucket_domain
  frontend_bucket_arn    = module.storage.frontend_bucket_arn
  api_gateway_endpoint   = module.compute.api_gateway_endpoint
  api_gateway_hostname   = module.compute.api_gateway_hostname
  cloudfront_logs_bucket = module.storage.cloudfront_logs_bucket

  depends_on = [ module.storage, module.compute ]
}
