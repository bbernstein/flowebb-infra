variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "frontend_domain" {
  description = "Frontend application domain"
  type        = string
}

variable "lambda_role_arn" {
  description = "ARN of the Lambda execution role"
  type        = string
}

variable "station_list_bucket_id" {
  description = "ID of the S3 bucket for station lists"
  type        = string
}

variable "lambda_memory_size" {
  description = "Amount of memory in MB for Lambda functions"
  type        = number
  default     = 512
}

variable "lambda_timeout" {
  description = "Timeout in seconds for Lambda functions"
  type        = number
  default     = 120
}

variable "log_retention_days" {
  description = "Number of days to retain logs in CloudWatch"
  type        = number
  default     = 30
}

variable "lambda_publish_version" {
  description = "Whether to publish a new Lambda version"
  type        = bool
  default     = false
}

variable "lambda_jar_path" {
  description = "Path to the Lambda JAR file"
  type        = string
  default     = null  # Make it optional
}

variable "lambda_jar_hash" {
  description = "Hash of the Lambda JAR file"
  type        = string
  default     = null  # Make it optional
}
