terraform {
  required_providers {
    aws = {
      configuration_aliases = [ aws.us-east-1 ]
    }
  }
}
