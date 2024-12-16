variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "dynamodb_table_arns" {
  description = "List of DynamoDB table ARNs"
  type        = list(string)
}

variable "station_list_bucket_arn" {
  description = "ARN of the station list S3 bucket"
  type        = string
}

variable "enable_cloudwatch_logs" {
  description = "Enable CloudWatch Logs permissions"
  type        = bool
  default     = true
}
