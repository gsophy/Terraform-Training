provider "aws" {
  region = "us-east-1"
}

# Commented out instance creation which was part of the Terraform Workspace example.  To create a new workspace, type terraform workspace new [workspace name].  to switch between workspaces, type terraform workspace select [workspace name]
# resource "aws_instance" "example" {
#   ami = "ami-0b69ea66ff7391e80"
#   instance_type = "t2.micro"
# }

resource "aws_s3_bucket" "terraform-state" {
  bucket = "soco-remote-state"

#Prevent accidential deletion of this s3 bucket
lifecycle {
    prevent_destroy = true
    }

#Enable versioning so we can see the full revision history of the state file
versioning {
    enabled = true
}

#Enable server-side encryption by default
server_side_encryption_configuration {
    rule {
        apply_server_side_encryption_by_default {
            sse_algorithm = "AES256"
            }
        }
    }
}

resource "aws_dynamodb_table" "terraform-locks" {
  name = "terraform-up-and-running-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key = "LockID"

  attribute {
      name = "LockID"
      type = "S"
  }
}

terraform {
    backend "s3" {
        bucket = "soco-remote-state"
        key = "workspaces-example/terraform.tfstate"
        region = "us-east-1"
        dynamodb_table = "terraform-up-and-running-locks"
    # Setting encrrypt to "true" ensures that your TFSTATE file will be encrypted on disk when stored in s3.  Although we've added encryption to the bucket itself, this is an added layer of security to ensure that the file is always encrypted.    
        encrypt = true
    }
}
output "s3_bucket_arn" {
    value = aws_s3_bucket.terraform-state.arn
    description = "The ARN of the s3 bucket"
}

output "dynamodb_table_name" {
    value = aws_dynamodb_table.terraform-locks.name
    description = "The name of the DynamoDB Table"
}