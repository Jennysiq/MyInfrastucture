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

data "aws_ami" "amazon_linux" {
  most_recent = true

  owners = ["amazon"]

  filter {
    name = "name"

    values = [
      "amzn-ami-hvm-*-x86_64-gp2",
    ]
  }

  filter {
    name = "owner-alias"

    values = [
      "amazon",
    ]
  }
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
  instance_count = 2

  name          = "myapp"
  ami           = data.aws_ami.amazon_linux.id
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

#data "aws_iam_policy_document" "bucket_policy" {
 # statement {
#    principals {
 #     type        = "AWS"
#      identifiers = [aws_iam_role.this.arn]
 #   }

#    actions = [
#      "s3:GetObject",
#    ]

 #   resources = [
  #    "arn:aws:s3:::${local.bucket_name}",
 #   ]
#  }
#}

#module "s3_bucket" {
 # source = "terraform-aws-modules/s3-bucket/aws"

  #bucket        = local.bucket_name
 # acl           = "private"
 # force_destroy = true

 # attach_policy = true
 # policy        = data.aws_iam_policy_document.bucket_policy.json

 # attach_deny_insecure_transport_policy = true

 # tags    = {
 #   Name  = "Myapp"
 #   Owner = "Jennysiq"
 # }

 # versioning = {
  #  enabled = true
 # }
#}
