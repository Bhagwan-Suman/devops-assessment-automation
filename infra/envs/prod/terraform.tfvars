project     = "hotelbook"
environment = "prod"
aws_region  = "ap-south-1"

# network - 3 AZs, NAT per AZ so one AZ outage doesn't cut egress
vpc_cidr             = "10.20.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
public_subnet_cidrs  = ["10.20.1.0/24", "10.20.2.0/24", "10.20.3.0/24"]
private_subnet_cidrs = ["10.20.11.0/24", "10.20.12.0/24", "10.20.13.0/24"]
single_nat_gateway   = false

# app - bigger tasks, at least 2 running across AZs
container_image         = "nginx:1.27-alpine"
container_port          = 80
task_cpu                = 512
task_memory             = 1024
desired_count           = 2
log_retention_days      = 90
container_insights      = true
alb_deletion_protection = true

# database - Multi-AZ, long retention, protected against accidental delete
db_instance_class        = "db.r6g.large"
db_allocated_storage     = 100
db_max_allocated_storage = 500
db_multi_az              = true
db_backup_retention_days = 30
db_deletion_protection   = true
db_skip_final_snapshot   = false
db_performance_insights  = true
