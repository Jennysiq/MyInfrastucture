provider "aws" {
  region = "us-east-1"
}

locals {
  user_data = <<EOF
!#/bin/bash
echo "DRASTE-MARDASTE"
EOF
}

#locals {
#  bucket_name = "s3-bucket-${random_pet.this.id}"
#}

##############DATA SOURCE VPC,Subnet,SG,AMI####################
data "aws_vpc" "default" {
  default  = true
}

data "aws_canonical_user_id" "current" {}

resource "random_pet" "this" {
  length = 2
}

data "aws_subnet_ids" "all" {
  vpc_id   = data.aws_vpc.default.id
}

data "aws_ami" "latest_ubuntu" {
  most_recent = true

  owners = ["${var.ubuntu_account_number}"]

  filter {
    name = "name"

    values = [
      "ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*",
    ]
  }

#  filter {
#    name = "owner-alias"

#    values = [
#      "amazon",
#    ]
#  }
}

module "security_group" {
  source  = "terraform-aws-modules/security-group/aws"
  version = "~> 4.0"

  name                = "MySGFlask"
  description         = "Security group for my E2C flask APP"
  vpc_id              = data.aws_vpc.default.id

  ingress_cidr_blocks = ["0.0.0.0/0"]
  ingress_rules       = ["http-80-tcp", "all-icmp"]
  egress_rules        = ["all-all"]

  tags                = {
    Owner             = "Jennysiq"
    Name              = "MyWebServer"
  }
}

module "ec2_with_t2_unlimited" {
  source = "terraform-aws-modules/ec2-instance/aws"
  instance_count = 1

  name          = "myapp"
  ami           = data.aws_ami.latest_ubuntu.id
  instance_type = "t2.micro"
  cpu_credits   = "unlimited"
  key_name      = "jenkins"
  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
  vpc_security_group_ids      = [module.security_group.security_group_id]
  associate_public_ip_address = true
  
  tags          = {
    Name        = "MyWebServer"
    Owner       = "Jennysiq"
  }
}
  
# module "ec2_with_t2_unlimited1" {
#  source = "terraform-aws-modules/ec2-instance/aws"
#  instance_count = 1

#  name          = "myappmon"
#  ami           = data.aws_ami.latest_ubuntu.id
#  instance_type = "t2.micro"
#  cpu_credits   = "unlimited"
#  key_name      = "jenkins"
#  subnet_id     = tolist(data.aws_subnet_ids.all.ids)[0]
#  vpc_security_group_ids      = [module.security_group.security_group_id]
# associate_public_ip_address = true
  
#  tags          = {
#    Name        = "MyWebServer4mon"
#    Owner       = "eugen"
#  }
#}
resource "aws_iam_role" "this" {
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
###################CREATE RDS MYSQL AND CONNECT WITH CREATED EC2#####################
resource "aws_db_instance" "flask_db" {
  identifier             = "flask_db"
  instance_class         = "db.t2.micro"
  allocated_storage      = 5
  engine                 = "mysql"
  engine_version         = "8.0.20"
  username               = "jennysiq"
  password               = var.db_password
  db_subnet_group_name   = aws_db_subnet_group.education.name
  vpc_security_group_ids = [aws_security_group.rds.id]
  parameter_group_name   = aws_db_parameter_group.education.name
  publicly_accessible    = true
  skip_final_snapshot    = true
}
  
