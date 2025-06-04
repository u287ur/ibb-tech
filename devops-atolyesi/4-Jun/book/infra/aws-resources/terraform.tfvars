tf_state_bucket = "tf-state-hakan"
tf_state_key    = "aws-resources/terraform.tfstate"
lock_table      = "terraform-locks"
region          = "us-east-1"

key_name = "jenkins-key"
ami_id = "ami-0d59d17fb3b322d0b"



backend_image_tag  = "backend:v1"
frontend_image_tag = "frontend:v1"
dockerhub_username = "your-dockerhub-username"