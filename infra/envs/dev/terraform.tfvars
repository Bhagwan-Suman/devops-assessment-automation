project     = "hotelbook"
environment = "dev"
aws_region  = "ap-south-1"

# network - 2 AZs, one shared NAT to keep the bill small
vpc_cidr             = "10.10.0.0/16"
azs                  = ["ap-south-1a", "ap-south-1b"]
public_subnet_cidrs  = ["10.10.1.0/24", "10.10.2.0/24"]
private_subnet_cidrs = ["10.10.11.0/24", "10.10.12.0/24"]
single_nat_gateway   = true

# app - smallest Fargate size, single task
container_image         = "nginx:1.27-alpine"
container_port          = 80
task_cpu                = 256
task_memory             = 512
desired_count           = 1
log_retention_days      = 7
container_insights      = false
alb_deletion_protection = false

# database - small, short retention, easy to tear down
db_instance_class        = "db.t4g.micro"
db_allocated_storage     = 20
db_max_allocated_storage = 50
db_multi_az              = false
db_backup_retention_days = 3
db_deletion_protection   = false
db_skip_final_snapshot   = true
db_performance_insights  = false
