provider "aws" {
  region = "us-east-1"
}

resource "aws_instance" "webserver" {
  ami = "ami-04b9e92b5572fa0d1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-traffic.id]
  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p 8080 &
                EOF
  tags = {
    Name = "Terraform-example"
  }
}

resource "aws_security_group" "web-traffic" {
  name = "terraform-example-ingress"
  ingress {
      from_port = 8080
      to_port = 8080
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}


