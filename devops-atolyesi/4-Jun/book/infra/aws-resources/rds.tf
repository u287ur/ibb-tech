resource "aws_db_subnet_group" "main" {
  name       = "rds-subnet-group"
  subnet_ids = data.terraform_remote_state.jenkins.outputs.private_subnets

  tags = {
    Name = "rds-subnet-group"
  }
}

resource "aws_db_instance" "mysql" {
  identifier            = "library-db"
  engine                = "mysql"
  engine_version        = "8.0"
  instance_class        = "db.t3.micro"
  allocated_storage     = 20
  storage_type          = "gp2"
  db_name               = var.db_name
  username              = var.db_username
  password              = var.db_password
  parameter_group_name  = "default.mysql8.0"

  db_subnet_group_name      = aws_db_subnet_group.main.name
  vpc_security_group_ids    = [aws_security_group.db_sg.id]

  skip_final_snapshot       = true
  publicly_accessible       = false
  multi_az                  = false
  backup_retention_period   = 0

  tags = {
    Name = "library-db"
  }
  timeouts {
    delete = "15m"  
  }

  depends_on = [aws_db_subnet_group.main]
}

resource "aws_security_group" "db_sg" {
  name        = "db-sg"
  description = "Allow MySQL traffic from backend"
  vpc_id      = data.terraform_remote_state.jenkins.outputs.vpc_id

  ingress {
    description     = "MySQL from backend"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [data.terraform_remote_state.jenkins.outputs.backend_sg_id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "db-sg"
  }
}
