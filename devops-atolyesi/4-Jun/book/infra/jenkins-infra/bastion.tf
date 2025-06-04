resource "aws_instance" "bastion" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = module.custom_vpc.public_subnets[0]

  key_name      = "jenkins-key"
  vpc_security_group_ids = [
    aws_security_group.bastion_sg.id
  ]
  associate_public_ip_address = true

  tags = {
    Name = "bastion-host"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y htop
              EOF
}
