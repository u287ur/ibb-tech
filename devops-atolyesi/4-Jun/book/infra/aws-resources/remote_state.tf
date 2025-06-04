# ✅ Reads the state file of the Jenkins infrastructure from S3
data "terraform_remote_state" "jenkins" {
  backend = "s3"
  config = {
    bucket         = "tf-state-hakan"            # Name of the S3 bucket where the Jenkins state file is stored
    key            = "jenkins/terraform.tfstate" # Path to the Jenkins module's state file
    region         = "us-east-1"                 # AWS region
    dynamodb_table = "terraform-locks"           # 🔐 DynamoDB table used for state locking
  }
}
