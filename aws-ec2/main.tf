terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
  }

  required_version = ">= 1.2.0"
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}


data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_s3_bucket" "kestra_s3_bucket" {
  bucket = var.s3_bucket
  tags = {
    Name = "kestra_s3_bucket"
  }
}

resource "aws_vpc" "kestra_vpc" {
  cidr_block           = var.vpc_cidr_block
  enable_dns_hostnames = true
  tags = {
    Name = "kestra_vpc"
  }
}

resource "aws_internet_gateway" "kestra_igw" {
  vpc_id = aws_vpc.kestra_vpc.id
  tags = {
    Name = "kestra_igw"
  }
}

resource "aws_subnet" "kestra_public_subnet" {
  count             = var.subnet_count.public
  vpc_id            = aws_vpc.kestra_vpc.id
  cidr_block        = var.public_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "kestra_public_subnet_${count.index}"
  }
}

resource "aws_subnet" "kestra_private_subnet" {
  count             = var.subnet_count.private
  vpc_id            = aws_vpc.kestra_vpc.id
  cidr_block        = var.private_subnet_cidr_blocks[count.index]
  availability_zone = data.aws_availability_zones.available.names[count.index]
  tags = {
    Name = "kestra_private_subnet_${count.index}"
  }
}

resource "aws_route_table" "kestra_public_rt" {
  vpc_id = aws_vpc.kestra_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.kestra_igw.id
  }
}

resource "aws_route_table_association" "public" {
  count          = var.subnet_count.public
  route_table_id = aws_route_table.kestra_public_rt.id
  subnet_id      = aws_subnet.kestra_public_subnet[count.index].id
}

resource "aws_route_table" "kestra_private_rt" {
  vpc_id = aws_vpc.kestra_vpc.id
}

resource "aws_route_table_association" "private" {
  count          = var.subnet_count.private
  route_table_id = aws_route_table.kestra_private_rt.id
  subnet_id      = aws_subnet.kestra_private_subnet[count.index].id
}

resource "aws_security_group" "kestra_web_sg" {
  name        = "kestra_web_sg"
  description = "Security group for kestra web servers"
  vpc_id      = aws_vpc.kestra_vpc.id
  ingress {
    description = "Allow all traffic through HTTP"
    from_port   = "8080"
    to_port     = "8080"
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "Allow SSH from my computer"
    from_port   = "22"
    to_port     = "22"
    protocol    = "tcp"
    # cidr_blocks = ["${var.my_ip}/32"]
    cidr_blocks = ["0.0.0.0/0"]

  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "kestra_web_sg"
  }
}

resource "aws_security_group" "kestra_db_sg" {
  name        = "kestra_db_sg"
  description = "Security group for kestra databases"
  vpc_id      = aws_vpc.kestra_vpc.id
  ingress {
    description     = "Allow Postgres traffic from only the web sg"
    from_port       = "5432"
    to_port         = "5432"
    protocol        = "tcp"
    security_groups = [aws_security_group.kestra_web_sg.id]
  }
  tags = {
    Name = "kestra_db_sg"
  }
}

resource "aws_db_subnet_group" "kestra_db_subnet_group" {
  // The name and description of the db subnet group
  name        = "kestra_db_subnet_group"
  description = "DB subnet group for kestra"
  subnet_ids  = [for subnet in aws_subnet.kestra_private_subnet : subnet.id]
}


resource "aws_key_pair" "kestra_kp_dev" {
  key_name = "kestra_key"

  // This is going to be the public key of our
  // ssh key. The file directive grabs the file
  // from a specific path. Since the public key
  // was created in the same directory as main.tf
  // we can just put the name
  public_key = tls_private_key.rsa.public_key_openssh
}

resource "tls_private_key" "rsa" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "local_file" "kestra_key_file" {
  content = tls_private_key.rsa.private_key_pem
  filename = "kestra_key"
}

resource "aws_instance" "kestra_web" {
  count                       = var.settings.kestra_app.count
  ami                         = var.settings.kestra_app.ami
  instance_type               = var.settings.kestra_app.instance_type
  subnet_id                   = aws_subnet.kestra_public_subnet[count.index].id
  key_name                    = aws_key_pair.kestra_kp_dev.key_name
  vpc_security_group_ids      = [aws_security_group.kestra_web_sg.id]
  associate_public_ip_address = true
 
  tags = {
    Name = "kestra_web_${count.index}"
  }
}

resource "aws_eip" "kestra_web_eip" {
  count    = var.settings.kestra_app.count
  instance = aws_instance.kestra_web[count.index].id
  vpc      = true
  tags = {
    Name = "kestra_web_eip_${count.index}"
  }
}