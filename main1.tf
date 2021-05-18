provider "aws" {
    shared_credentials_file = "$HOME/.aws/credentials"
    profile                 = "notes-app"
    region                  = var.aws_region
}

module "vpc" {
    source = "../../modules/vpc-double"
    vpc_name = "db-sample"
    vpc_cidr = "192.168.0.0/16"
    public_cidr = "192.168.1.0/24"
    private1_cidr = "192.168.2.0/24"
    private2_cidr = "192.168.3.0/24"
    private1_az = data.aws_availability_zones.available.names[0]
    private2_az = data.aws_availability_zones.available.names[1]
    public_az = data.aws_availability_zones.available.names[0]
}

data "aws_availability_zones" "available" {
  state = "available"
}
  
resource "aws_instance" "public-ec2" {
    ami           = var.ami_id
    instance_type = var.instance_type
    subnet_id     = module.vpc.subnet_public_id
    key_name      = "notes-app-key-pair"
    vpc_security_group_ids = [ aws_security_group.ec2-sg.id ]
    associate_public_ip_address = true

    tags = {
        Name = "ec2-main"
    }

    depends_on = [ module.vpc.vpc_id, module.vpc.igw_id ]

    user_data = <<EOF
#!/bin/sh
sudo apt-get update
sudo apt-get install -y mysql-client
EOF
}

resource "aws_security_group" "ec2-sg" {
  name        = "security-group"
  description = "allow inbound access to the EC2 instance"
  vpc_id      = module.vpc.vpc_id

  ingress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
}
  
resource "aws_db_parameter_group" "default" {
  name   = "rds-pg"
  family = "mysql8.0"

  parameter {
    name  = "character_set_server"
    value = "utf8"
  }

  parameter {
    name  = "character_set_client"
    value = "utf8"
  }
}

resource "aws_db_subnet_group" "default" {
  name       = "main"
  subnet_ids = [ module.vpc.subnet_private1_id , module.vpc.subnet_private2_id ]

  tags = {
    Name = "My DB subnet group"
  }
}

    
resource "aws_security_group" "rds-sg" {
  name        = "rds-security-group"
  description = "allow inbound access to the database"
  vpc_id      = module.vpc.vpc_id

  ingress {
    // protocol    = "tcp"
    // from_port   = 0
    // to_port     = 3306
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ module.vpc.vpc_cidr ]
  }

  egress {
    protocol    = "-1"
    from_port   = 0
    to_port     = 0
    cidr_blocks = [ module.vpc.vpc_cidr ]
  }
}
  
resource "aws_db_instance" "default" {
  allocated_storage    = 100
  storage_type         = "gp2"
  engine               = "mysql"
  engine_version       = "8.0"
  instance_class       = "db.t2.micro"
  identifier           = "mydb"
  name                 = "mydb"
  username             = "root"
  password             = "foobarbaz"
  parameter_group_name = aws_db_parameter_group.default.id
  db_subnet_group_name = aws_db_subnet_group.default.id
  vpc_security_group_ids = [ aws_security_group.rds-sg.id ]
  publicly_accessible  = false
  skip_final_snapshot  = true
  multi_az             = false
}
