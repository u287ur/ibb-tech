terraform {
  backend "s3" {
    bucket         = var.tf_state_bucket
    key            = var.tf_state_key
    region         = var.region
    dynamodb_table = var.lock_table
  }
}

provider "aws" {
  region = var.region
}
