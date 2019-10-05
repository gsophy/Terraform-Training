provider "aws" {
  region = "us-east-1"
}
variable "webserver-port" {
  description = "The port the webserver will use for HTTP Traffic"
  type = number
  default = 8080
}

resource "aws_instance" "webserver" {
  ami = "ami-04b9e92b5572fa0d1"
  instance_type = "t2.micro"
  vpc_security_group_ids = [aws_security_group.web-traffic.id]
  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.webserver-port} &
                EOF
  tags = {
    Name = "Terraform-example"
  }
}

resource "aws_security_group" "web-traffic" {
  name = "terraform-example-ingress"
  ingress {
      from_port = var.webserver-port
      to_port = var.webserver-port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

output "securitygroup-id" {
  description = "The ARN of the web-traffic security group"
  value = aws_security_group.web-traffic.id
}

output "instance-id" {
  description = "The ARN of the web-server instance"
  value = aws_instance.webserver.id
}

output "public_ip" {
  description = "The public IP interface of the web server"
  value = aws_instance.webserver.public_ip
}