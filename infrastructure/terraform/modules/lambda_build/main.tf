terraform {
  required_version = ">= 1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

resource "null_resource" "build_lambda" {
  triggers = {
    always_run = timestamp()
  }

  provisioner "local-exec" {
    command = "cd ${path.root}/../../../../backend && ./gradlew build"
  }
}

locals {
  lambda_jar_path = "${path.root}/../../../../backend/build/libs/tides-be.jar"
}
