# Terraform Backend Configuration

terraform {
  backend "s3" {
    bucket         = "REPLACE_WITH_ACCOUNT_ID-soc-tf-state"
    key            = "soc/terraform.tfstate"
    region         = "ap-northeast-1"
    encrypt        = true
    dynamodb_table = "soc-tf-locks"
  }

  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}