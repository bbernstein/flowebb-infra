terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 5.0"
      alias                 = "us-east-1"
      configuration_aliases = ["us-east-1"]
    }
  }
}
