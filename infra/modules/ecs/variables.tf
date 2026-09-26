variable "name" {
  type = string
}

variable "aws_region" {
  type = string
}

variable "vpc_id" {
  type = string
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "alb_sg_id" {
  type = string
}

variable "ecs_sg_id" {
  type = string
}

variable "container_image" {
  description = "Image to run, e.g. nginx:1.27-alpine"
  type        = string
}

variable "container_port" {
  type = number
}

variable "health_check_path" {
  type    = string
  default = "/"
}

variable "task_cpu" {
  description = "Fargate CPU units (256 = 0.25 vCPU)"
  type        = number
}

variable "task_memory" {
  description = "Fargate memory in MiB"
  type        = number
}

variable "desired_count" {
  type = number
}

variable "log_retention_days" {
  type = number
}

variable "container_insights" {
  type    = bool
  default = false
}

variable "alb_deletion_protection" {
  type    = bool
  default = false
}

variable "db_host" {
  type = string
}

variable "db_port" {
  type    = number
  default = 5432
}

variable "db_name" {
  type = string
}

variable "db_secret_arn" {
  description = "ARN of the RDS-managed master user secret"
  type        = string
}
