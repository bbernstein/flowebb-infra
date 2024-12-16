variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "domain_name" {
  description = "Root domain name"
  type        = string
}

variable "frontend_domain" {
  description = "Frontend application domain"
  type        = string
}

variable "api_domain" {
  description = "API domain"
  type        = string
}

variable "frontend_bucket_domain" {
  description = "Domain name of the frontend S3 bucket"
  type        = string
}

variable "frontend_bucket_arn" {
  description = "ARN of the frontend S3 bucket"
  type        = string
}

variable "api_gateway_endpoint" {
  description = "API Gateway endpoint URL"
  type        = string
}

variable "api_gateway_hostname" {
  description = "API Gateway hostname"
  type        = string
}

variable "cloudfront_logs_bucket" {
  description = "Name of the S3 bucket for CloudFront logs"
  type        = string
}

