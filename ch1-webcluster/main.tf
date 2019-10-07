provider "aws" {
  region = "us-east-1"
}

variable "server_port" {
  description = "The port that the server will accept HTTP traffic"
  type = number
  default = 8080
}

data aws_vpc "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}

resource "aws_launch_configuration" "example-launch-config" {
  image_id = "ami-04b9e92b5572fa0d1"
  instance_type = "t2.micro"
  security_groups = [aws_security_group.web-traffic.id]

  user_data = <<-EOF
                #!/bin/bash
                echo "Hello, World" > index.html
                nohup busybox httpd -f -p ${var.server_port} &
                EOF
# Required when using a launch configuration with an autoscaling group.
lifecycle {
    create_before_destroy = true
}
}

resource "aws_autoscaling_group" "example-ASG" {
  launch_configuration = aws_launch_configuration.example-launch-config.name
  vpc_zone_identifier = data.aws_subnet_ids.default.ids
  min_size = 2
  max_size = 10

  tag {
      key =     "Name"
      value =   "terraform-asg-example"
      propagate_at_launch = true
  }
}

resource "aws_security_group" "web-traffic" {
  name = "terraform-example-ingress"
  ingress {
      from_port = var.server_port
      to_port = var.server_port
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb" "example-loadbalancer" {
  name = "terraform-asg-example"
  load_balancer_type = "application"
  subnets = data.aws_subnet_ids.default.ids
}

resource "aws_alb_listener" "http" {
  load_balancer_arn = aws.lb.example-loadbalancer.arn
  port = 80
  protocol = "HTTP"
  # By default, retun a simple 404 page
  default_action {
      type = "fixed-response"
      fixed-response {
          content-message = "text/plain"
          message-body = "404: Page Not Found"
          status-code = 404
      }
  }
}






