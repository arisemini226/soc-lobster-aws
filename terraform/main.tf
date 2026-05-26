#=======================================
# SOC 龍蝦系統 — Terraform 主設定
# AWS Region: ap-northeast-1
# PoC 模式，預算 $150/month
#=======================================

terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-northeast-1"
}

#=======================================
# Data Sources
#=======================================
data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

#=======================================
# VPC 網路架構
#=======================================
resource "aws_vpc" "soc_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "SOC-VPC"
    Environment = var.environment
    Owner       = var.owner
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.soc_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-northeast-1a"
  map_public_ip_on_launch = true

  tags = {
    Name        = "SOC-Public-Subnet"
    Environment = var.environment
  }
}

resource "aws_internet_gateway" "soc_igw" {
  vpc_id = aws_vpc.soc_vpc.id

  tags = {
    Name        = "SOC-IGW"
    Environment = var.environment
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.soc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.soc_igw.id
  }

  tags = {
    Name        = "SOC-Public-RT"
    Environment = var.environment
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

#=======================================
# 安全群組
#=======================================
resource "aws_security_group" "soc_sg" {
  name        = "SOC-SG"
  description = "Security group for SOC OpenClaw server"
  vpc_id      = aws_vpc.soc_vpc.id

  ingress = [
    {
      description = "SSH"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTP"
      from_port   = 80
      to_port     = 80
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "HTTPS"
      from_port   = 443
      to_port     = 443
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    },
    {
      description = "OpenClaw Gateway"
      from_port   = 18789
      to_port     = 18789
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  egress = [
    {
      description = "All outbound"
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }
  ]

  tags = {
    Name        = "SOC-SG"
    Environment = var.environment
  }
}

#=======================================
# IAM Role（給 OpenClaw AWS 權限）
#=======================================
resource "aws_iam_role" "soc_role" {
  name = "SOC-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"
        }
      }
    ]
  })

  tags = {
    Name        = "SOC-Role"
    Environment = var.environment
  }
}

# PoC 階段用 AdministratorAccess，之後用 Access Analyzer 限縮
resource "aws_iam_role_policy_attachment" "soc_admin" {
  role       = aws_iam_role.soc_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "soc_profile" {
  name = "SOC-Instance-Profile"
  role = aws_iam_role.soc_role.name
}

#=======================================
# EC2 執行個體（m5.large 省錢模式）
#=======================================
resource "aws_instance" "soc_server" {
  ami               = var.ami_id
  instance_type     = var.instance_type
  subnet_id         = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.soc_sg.id]
  iam_instance_profile = aws_iam_instance_profile.soc_profile.name
  key_name          = var.key_pair_name

  user_data = <<-EOF
#!/bin/bash
set -euxo pipefail

# 記錄日誌
exec > >(tee /var/log/user-data.log|logger -t user-data -s 2>/dev/console) 2>&1
echo "===== Starting SOC Server Setup ====="

# 更新系統
sudo yum update -y

# 安裝 Docker
sudo amazon-linux-extras install docker -y
sudo systemctl start docker
sudo systemctl enable docker
sudo usermod -a -G docker ec2-user

# 安裝 Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/download/v2.24.0/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 安裝 AWS CLI v2
sudo curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "/tmp/awscliv2.zip"
sudo unzip -q /tmp/awscliv2.zip -d /tmp
sudo /tmp/aws/install
rm -rf /tmp/awscliv2.zip /tmp/aws

# 安裝 Terraform
sudo yum install -y yum-utils
sudo yum-config-manager --add-repo "https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo"
sudo yum install -y terraform

# 安裝 OpenClaw
curl -fsSL https://openclaw.ai/install.sh | bash

echo "===== SOC Server Setup Complete ====="
EOF

  tags = {
    Name        = "SOC-OpenClaw-Server"
    Project     = "SOC-龍蝦"
    Environment = var.environment
  }

  root_block_device {
    volume_size = var.root_volume_size
    volume_type = "gp3"
    delete_on_termination = true
  }
}

#=======================================
# 彈性 IP
#=======================================
resource "aws_eip" "soc_eip" {
  instance = aws_instance.soc_server.id
  domain   = "vpc"

  tags = {
    Name        = "SOC-Elastic-IP"
    Environment = var.environment
  }
}

#=======================================
# S3 Bucket（Terraform State + 日誌）
#=======================================
resource "aws_s3_bucket" "soc_state" {
  bucket = "${data.aws_caller_identity.current.account_id}-soc-tf-state"

  tags = {
    Name        = "SOC-Terraform-State"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_versioning" "soc_state_versioning" {
  bucket = aws_s3_bucket.soc_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "soc_state_encrypt" {
  bucket = aws_s3_bucket.soc_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

#=======================================
# DynamoDB Table（Terraform State Lock）
#=======================================
resource "aws_dynamodb_table" "tf_locks" {
  name         = "soc-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "SOC-TF-Locks"
    Environment = var.environment
  }
}

#=======================================
# Outputs
#=======================================
output "ec2_public_ip" {
  description = "EC2 Public IP"
  value       = aws_instance.soc_server.public_ip
}

output "elastic_ip" {
  description = "Elastic IP"
  value       = aws_eip.soc_eip.public_ip
}

output "ssh_command" {
  description = "SSH Command"
  value       = "ssh -i ${var.key_pair_name}.pem ec2-user@${aws_eip.soc_eip.public_ip}"
}

output "openclaw_gateway_url" {
  description = "OpenClaw Gateway URL"
  value       = "http://${aws_eip.soc_eip.public_ip}:18789"
}

output "s3_bucket" {
  description = "S3 Bucket for Terraform State"
  value       = aws_s3_bucket.soc_state.bucket
}

output "vpc_id" {
  description = "VPC ID"
  value       = aws_vpc.soc_vpc.id
}

output "ec2_instance_id" {
  description = "EC2 Instance ID"
  value       = aws_instance.soc_server.id
}