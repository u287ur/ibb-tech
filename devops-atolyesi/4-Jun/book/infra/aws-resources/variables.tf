# AWS Region to deploy resources
variable "region" {
  description = "AWS region to deploy resources"
  type        = string
}

# EC2 Key Pair for SSH access
variable "key_name" {
  description = "Name of the existing AWS key pair for SSH access"
  type        = string
}

# Amazon Machine Image (AMI) ID for EC2 instances
variable "ami_id" {
  description = "AMI ID to use for EC2 instances (e.g., Ubuntu 24.04)"
  type        = string
  default     = "ami-0d59d17fb3b322d0b"
}

# S3 bucket name for storing the Terraform remote state
variable "tf_state_bucket" {
  description = "S3 bucket name to store the Terraform remote state"
  type        = string
}

# DynamoDB table name for state locking
variable "lock_table" {
  description = "DynamoDB table name for Terraform state locking"
  type        = string
}

# DockerHub credentials for image pull/push
variable "dockerhub_username" {
  description = "DockerHub username to authenticate Docker image operations"
  type        = string
}

variable "dockerhub_password" {
  description = "DockerHub password for authentication"
  type        = string
  sensitive   = true
}

# RDS (MySQL) database credentials
variable "db_username" {
  description = "Username for connecting to the RDS MySQL database"
  type        = string
}

variable "db_password" {
  description = "Password for connecting to the RDS MySQL database"
  type        = string
  sensitive   = true
}

# Django backend secret key
variable "secret_key" {
  description = "Django SECRET_KEY used for backend encryption and session management"
  type        = string
  sensitive   = true
}

# Docker image tags (dynamically passed from Jenkins build)
variable "backend_image_tag" {
  description = "Tag for the backend Docker image (e.g., build-123)"
  type        = string
}

variable "frontend_image_tag" {
  description = "Tag for the frontend Docker image (e.g., build-123)"
  type        = string
}
variable "db_name" {
  description = "Name of the RDS database"
  type        = string
}
variable "tf_state_key" {
  description = "Key name for remote state file"
  type        = string
}
