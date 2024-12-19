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
