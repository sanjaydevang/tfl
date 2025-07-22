# This block configures the "backend", which tells Terraform
# where to store its state file and how to handle locking.
terraform {
  backend "s3" {
    # The name of the S3 bucket where the state file will be stored.
    # This bucket must be created beforehand.
    bucket         = "terraform-state-sanjay-1753188027"

    # The path and filename for the state file within the bucket.
    key            = "production/network/terraform.tfstate"
    
    # The AWS region where the bucket resides.
    region         = "us-east-1"

    # The name of the DynamoDB table used for state locking.
    # This table must also be created beforehand with a primary key named "LockID".
    dynamodb_table = "terraform-state-lock-table"
  }
}