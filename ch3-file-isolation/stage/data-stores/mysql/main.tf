provider "aws" {
  region = "us-east-1"
}

resource "aws_db_instance" "example" {
  identifier_prefix = "terraform-up-and-running"
  engine = "mysql"
  allocated_storage = 10
  instance_class = "db.t2.micro"
  name = "example_database"
  username = "admin"
  skip_final_snapshot = true
  final_snapshot_identifier = "foo"

# How should we set the password?
  password = var.db_password
}

terraform {
    backend "s3" {
        bucket = "soco-remote-state"
        key = "stage/data-stores/mysql/terraform-tfstate"
        region = "us-east-1"

        dynamodb_table = "terraform-up-and-running-locks"
        encrypt = true
    }
}