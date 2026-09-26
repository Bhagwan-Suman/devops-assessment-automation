terraform {
  backend "s3" {
    bucket       = "hotelbook-tfstate-prod"
    key          = "envs/prod/terraform.tfstate"
    region       = "ap-south-1"
    encrypt      = true
    use_lockfile = true # native S3 state locking (Terraform 1.10+)
  }
}
