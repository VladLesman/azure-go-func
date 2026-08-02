variable "location" {
  type        = string
  default     = "Canada Central"
  description = "Azure region for all resources"
}

variable "environment" {
  type        = string
  default     = "dev"
  description = "Environment name (dev, stage, prod)"
}

variable "project_name" {
  type        = string
  default     = "gofunc"
  description = "Project prefix for resource naming"
}