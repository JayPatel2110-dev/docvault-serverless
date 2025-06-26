terraform {
    required_providers {
        aws = {
        source  = "hashicorp/aws"
        version = "~> 6.0"
        }
    }
}

provider "aws" {
    region = "ap-south-1"
}

terraform {
  backend "s3" {
    bucket         = "infosec-terraform-state-backend" // Replace with your state management S3 bucket name
    key            = "doc_vault/terraform.tfstate"
    region         = "ap-south-1"
    dynamodb_table = "terraform-locks"
    encrypt        = true
  }
}