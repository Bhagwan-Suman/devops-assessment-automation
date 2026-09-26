provider "aws" {
  region = var.aws_region

  # plan_only = true lets reviewers / CI run `terraform plan` without real
  # AWS credentials. The real deployment pipeline sets TF_VAR_plan_only=false
  # and authenticates through GitHub OIDC.
  access_key                  = var.plan_only ? "mock_access_key" : null
  secret_key                  = var.plan_only ? "mock_secret_key" : null
  skip_credentials_validation = var.plan_only
  skip_requesting_account_id  = var.plan_only
  skip_metadata_api_check     = var.plan_only

  default_tags {
    tags = {
      Project     = var.project
      Environment = var.environment
      ManagedBy   = "terraform"
    }
  }
}
