variable "name" {
  description = "Name prefix, e.g. hotelbook-dev"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "azs" {
  description = "Availability zones to spread subnets across"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "One public subnet CIDR per AZ"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "One private subnet CIDR per AZ"
  type        = list(string)
}

variable "single_nat_gateway" {
  description = "true = one shared NAT (cheap, dev). false = one NAT per AZ (HA, prod)"
  type        = bool
  default     = true
}

variable "container_port" {
  description = "Port the application container listens on"
  type        = number
}

variable "db_port" {
  description = "Database port"
  type        = number
  default     = 5432
}
