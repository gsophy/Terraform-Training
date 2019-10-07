provider "aws" {
  region = us-east-1
}

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
