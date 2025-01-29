variable "project_name" {
  description = "Project name"
  type        = string
}

variable "environment" {
  description = "Environment name"
  type        = string
}

variable "frontend_domain" {
  description = "Frontend application domain - used for S3 bucket name"
  type        = string
}

variable "lifecycle_rule_days" {
  description = "Number of days after which objects should be deleted"
  type        = number
  default     = 7
}
