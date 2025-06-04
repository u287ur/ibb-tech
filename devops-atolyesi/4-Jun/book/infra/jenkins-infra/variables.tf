# AWS Region to deploy resources
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

variable "key_name" {
  description = "Name of the existing AWS key pair for SSH access"
  type        = string
}

variable "ami_id" {
  description = "AMI ID to use for EC2 instances (Ubuntu 24.04)"
  type        = string
  default     = "ami-0d59d17fb3b322d0b"
}

# Backend için state store
variable "tf_state_bucket" {
  description = "S3 bucket name to store the Terraform state"
  type        = string
}

variable "lock_table" {
  description = "DynamoDB table name for state locking"
  type        = string
}

# VPC ile ilgili değişkenler
variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "availability_zones" {
  default = ["us-east-1a", "us-east-1b"]
}

variable "public_subnets" {
  description = "List of public subnet CIDRs or IDs"
  type        = list(string)
}

variable "private_subnets" {
  description = "List of private subnet CIDRs or IDs"
  type        = list(string)
}

variable "tf_state_key" {
  description = "Key name for remote state file"
  type        = string
}
