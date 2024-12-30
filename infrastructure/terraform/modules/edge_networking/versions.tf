terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"

      # tflint:ignore:AWS_REGION
      configuration_aliases = [aws.us-east-1]
    }
  }
}
