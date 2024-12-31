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
    command = <<-EOT
      cd ${path.root}/../../../../backend-go && \
      GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o bootstrap ./cmd/stations && \
      zip stations.zip bootstrap && \
      GOOS=linux GOARCH=arm64 CGO_ENABLED=0 go build -o bootstrap ./cmd/tides && \
      zip tides.zip bootstrap
    EOT
  }
}
