terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# -------------------------------
# 1. VPC and Networking Resources
# -------------------------------

resource "aws_vpc" "main_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name  = "sanjay-vpc"
    Owner = "sanjay-tf"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "us-east-1a"

  tags = {
    Name  = "sanjay-public-subnet"
    Owner = "sanjay-tf"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name  = "sanjay-igw"
    Owner = "sanjay-tf"
  }
}

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name  = "sanjay-public-rt"
    Owner = "sanjay-tf"
  }
}

resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_security_group" "web_sg" {
  name        = "sanjay-web-sg"
  description = "Allow SSH access from specific IP"
  vpc_id      = aws_vpc.main_vpc.id

  # ✅ FIXED: Only allow SSH from your specific IP (more secure)
  ingress {
    description = "Allow SSH from my IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["73.133.42.125/32"]
  }

  egress {
    description = "Allow all outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name  = "sanjay-web-sg"
    Owner = "sanjay-tf"
  }
}

# -------------------------------
# 2. Key Pair (moved up for better organization)
# -------------------------------

resource "aws_key_pair" "sanjay_key" {
  key_name   = "sanjay-key"
  public_key = file("~/.ssh/id_rsa.pub")  # Make sure this file exists
  
  tags = {
    Name  = "sanjay-key"
    Owner = "sanjay-tf"
  }
}

# -------------------------------
# 3. IAM Role + Instance Profile
# -------------------------------

resource "aws_iam_role" "web_server_role" {
  name = "sanjay-tf-web-server-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
  })

  tags = {
    Name  = "SanjayTfWebServerRole"
    Owner = "sanjay-tf"
  }
}

resource "aws_iam_instance_profile" "web_server_profile" {
  name = "sanjay-tf-web-server-profile"
  role = aws_iam_role.web_server_role.name
}

# Optional: Attach managed policy if needed
# resource "aws_iam_role_policy_attachment" "ssm" {
#   role       = aws_iam_role.web_server_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# -------------------------------
# 4. EC2 Instance
# -------------------------------

resource "aws_instance" "web_server" {
  count         = 1
  ami           = "ami-051f8a213df8bc089"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id

  key_name               = aws_key_pair.sanjay_key.key_name
  vpc_security_group_ids = [aws_security_group.web_sg.id]

  iam_instance_profile = aws_iam_instance_profile.web_server_profile.name
  ebs_optimized        = true
  monitoring           = true

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 8
    encrypted             = true
    delete_on_termination = true
  }

  tags = {
    Name  = "MyFirstTerraformServer-${count.index + 1}"
    Owner = "sanjay-tf"
  }
}

# -------------------------------
# 5. Outputs
# -------------------------------

output "web_server_public_ips" {
  description = "The public IP addresses of the EC2 instance(s)"
  value       = [for instance in aws_instance.web_server : instance.public_ip]
}

output "ssh_connection_command" {
  description = "SSH command to connect to the instance"
  value       = [for instance in aws_instance.web_server : "ssh -i ~/.ssh/id_rsa ec2-user@${instance.public_ip}"]
}