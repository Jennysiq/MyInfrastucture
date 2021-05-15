provider "aws" {
    region     = "us-east-1"

data "aws_instances" "webserver_instans" {
  instance_tags = {
    Name = "FlaskAPP"
  }

  filter {
      name   = "tag:Name"
      values = ["FlaskAPP"]
  }
}

output "aws_instans_public_ip" {
    value = data.aws_instances.webserver_instans.public_ips
}

resource "aws_security_group" "webSG" {
  name = "Dynamic Security Group"

  dynamic "ingress" {
    for_each = ["80","22", "5000"]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "Dymanic SG for APP"
  }
}

resource "random_string" "random" {
  length = 16
  special = false
  min_lower = 16
}

resource "aws_kms_key" "this" {}
resource "aws_s3_bucket" "that" {
  bucket = "${random_string.random.result}"
}