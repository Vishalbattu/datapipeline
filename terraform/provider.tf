provider "aws" {
  region = "us-west-2"  
}

terraform {
  backend "s3" {
    bucket = "terraformstate-bucket-d"  # S3 bucket for storing my Terraform state
    key    = "tfstatefiles/terraform.tfstate"  # state file path
    region = "us-west-2"  # S3 bucket Region 
  }
}
