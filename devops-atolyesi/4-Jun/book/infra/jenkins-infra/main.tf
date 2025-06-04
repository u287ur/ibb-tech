module "custom_vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.5.1"

  name               = var.vpc_name
  cidr               = var.vpc_cidr
  azs                = var.availability_zones
  public_subnets     = var.public_subnets
  private_subnets    = var.private_subnets

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Project = "jenkins-infra"
  }
}


# RSA key pair 
resource "tls_private_key" "jenkins_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "jenkins_key" {
  key_name   = var.key_name
  public_key = tls_private_key.jenkins_key.public_key_openssh
}

resource "local_file" "private_key" {
  filename        = "${path.module}/${var.key_name}.pem"
  content         = tls_private_key.jenkins_key.private_key_pem
  file_permission = "0400"
}

# Jenkins için Security Group
resource "aws_security_group" "jenkins_sg" {
  name        = "jenkins-sg"
  description = "Allow SSH and Jenkins Web"
  vpc_id      = module.custom_vpc.vpc_id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Jenkins UI"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "jenkins-sg"
  }
}

data "aws_iam_policy_document" "jenkins_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "jenkins_role" {
  name               = "jenkins-role"
  assume_role_policy = data.aws_iam_policy_document.jenkins_assume.json
}

resource "aws_iam_role_policy_attachment" "jenkins_admin" {
  role       = aws_iam_role.jenkins_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "jenkins_profile" {
  name = "jenkins-profile"
  role = aws_iam_role.jenkins_role.name
}

resource "aws_instance" "jenkins" {
  ami                         = var.ami_id
  instance_type               = "t3.small"
  key_name                    = var.key_name
  subnet_id                   = module.custom_vpc.public_subnets[0]
  vpc_security_group_ids      = [aws_security_group.jenkins_sg.id]
  associate_public_ip_address = true
  iam_instance_profile        = aws_iam_instance_profile.jenkins_profile.name
  user_data                   = file("scripts/jenkins_setup.sh")
  root_block_device {
    volume_size = 50          
    volume_type = "gp2"      
    delete_on_termination = true
  }

  depends_on = [ 
    aws_key_pair.jenkins_key,
    local_file.private_key
  ]

  tags = {
    Name = "jenkins-ci"
  }
}

