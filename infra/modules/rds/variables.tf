variable "name" {
  type = string
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "rds_sg_id" {
  type = string
}

variable "engine_version" {
  type    = string
  default = "16"
}

variable "instance_class" {
  type = string
}

variable "allocated_storage" {
  type = number
}

variable "max_allocated_storage" {
  description = "Upper limit for storage autoscaling (GiB)"
  type        = number
}

variable "db_name" {
  type = string
}

variable "db_username" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "multi_az" {
  type = bool
}

variable "backup_retention_days" {
  type = number

  validation {
    condition     = var.backup_retention_days >= 1 && var.backup_retention_days <= 35
    error_message = "RDS backup retention must be between 1 and 35 days."
  }
}

variable "deletion_protection" {
  type = bool
}

variable "skip_final_snapshot" {
  type = bool
}

variable "performance_insights_enabled" {
  type    = bool
  default = false
}

variable "apply_immediately" {
  type    = bool
  default = false
}
