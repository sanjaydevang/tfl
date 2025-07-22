# 1. Configure the AWS Provider
# This tells Terraform we are going to be working with AWS
# and in which region we want to create our resources.
provider "aws" {
  region = "us-east-1"
}

# 2. Define a Resource (our EC2 instance)
# This block tells Terraform to create an AWS EC2 instance.
resource "aws_instance" "web_server" {
  count = 10
  # ami is the Amazon Machine Image ID - this one is for Amazon Linux 2
  ami           = "ami-051f8a213df8bc089" 
  
  # instance_type defines the size and power of the server
  instance_type = "t2.micro"

  # Tags are key-value pairs to help organize resources
  tags = {
Name = "MyFirstTerraformServer-${count.index + 1}"
  }
}

# 3. Define an Output
# This will print the public IP address of our server after it's created.
output "web_server_public_ips" {
  description = "The public IP addresses of all web servers."
  value       = [for instance in aws_instance.web_server : instance.public_ip]
}




