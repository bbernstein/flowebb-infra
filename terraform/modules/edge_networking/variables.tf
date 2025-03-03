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

variable "api_gateway_hostname" {
  description = "API Gateway hostname"
  type        = string
}

variable "cloudfront_logs_bucket" {
  description = "Name of the S3 bucket for CloudFront logs"
  type        = string
}

variable "certificate_arn" {
  description = "ARN of the ACM certificate"
  type        = string
}

variable "route53_zone_id" {
  description = "ID of the Route53 zone"
  type        = string
}
