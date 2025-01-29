variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "prod"
}

variable "project_name" {
  description = "Project name"
  type        = string
  default     = "tides-app"
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
  default     = "flowebb.com"
}

variable "frontend_domain" {
  description = "Frontend application domain"
  type        = string
  default     = "app.flowebb.com"
}

variable "api_domain" {
  description = "API domain"
  type        = string
  default     = "api.flowebb.com"
}
