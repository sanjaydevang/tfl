# 1. Configure the AWS Provider
# This tells Terraform we are going to be working with AWS
# and in which region we want to create our resources.
terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider with region
provider "aws" {
  region = "us-east-1"
}

# 2. Create IAM Role for EC2 Instance
# This role allows the EC2 instance to interact with AWS services securely
resource "aws_iam_role" "web_server_role" {
  name = "sanjay-tf-web-server-role"

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
    Name = "SanjayTfWebServerRole"
    Owner = "sanjay-tf"
  }
}

# Create instance profile for the IAM role
resource "aws_iam_instance_profile" "web_server_profile" {
  name = "sanjay-tf-web-server-profile"
  role = aws_iam_role.web_server_role.name
}

# Optional: Attach basic policies (uncomment if needed)
# resource "aws_iam_role_policy_attachment" "ssm_managed_instance_core" {
#   role       = aws_iam_role.web_server_role.name
#   policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
# }

# 3. Define a Resource (our EC2 instance)
# This block tells Terraform to create an AWS EC2 instance.
resource "aws_instance" "web_server" {
  count = 1
  # ami is the Amazon Machine Image ID - this one is for Amazon Linux 2
  ami           = "ami-051f8a213df8bc089" 
  
  # instance_type defines the size and power of the server
  instance_type = "t2.micro"

  # ✅ Security Fix: Attach IAM role to EC2 instance
  iam_instance_profile = aws_iam_instance_profile.web_server_profile.name

  # ✅ Security Fix: Enable EBS optimization
  ebs_optimized = true
  
  # ✅ Security Fix: Enable detailed monitoring
  monitoring = true
  
  # ✅ Security Fix: Configure secure Instance Metadata Service (IMDSv2 only)
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required"    # Require IMDSv2
    http_put_response_hop_limit = 1
    instance_metadata_tags      = "enabled"
  }
  
  # ✅ Security Fix: Encrypt root EBS volume
  root_block_device {
    volume_type = "gp3"
    volume_size = 8
    encrypted   = true
    delete_on_termination = true
  }

  # Tags are key-value pairs to help organize resources
  tags = {
    Name = "MyFirstTerraformServer-${count.index + 1}"
    Owner = "sanjay-tf"
  }
}

# 4. Define an Output
# This will print the public IP address of our server after it's created.
output "web_server_public_ips" {
  description = "The public IP addresses of all web servers."
  value       = [for instance in aws_instance.web_server : instance.public_ip]
}