tf_state_bucket = "tf-state-hakan"
tf_state_key    = "jenkins/terraform.tfstate"
lock_table      = "terraform-locks"
region          = "us-east-1"

key_name = "jenkins-key"
ami_id = "ami-0d59d17fb3b322d0b"

vpc_name = "jenkins-vpc"
vpc_cidr = "10.0.0.0/16"
availability_zones = ["us-east-1a", "us-east-1b"]
public_subnets     = ["10.0.1.0/24", "10.0.2.0/24"]
private_subnets    = ["10.0.3.0/24", "10.0.4.0/24"]
