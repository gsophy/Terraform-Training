provider "aws" {
  region = "us-east-1"
}

data aws_vpc "default" {
    default = true
}

data "aws_subnet_ids" "default" {
    vpc_id = data.aws_vpc.default.id
}
## Add terraform remote state to web cluster deployment
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
  
  target_group_arns = [aws_lb_target_group.asg.arn]
  health_check_type = "ELB"

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
  security_groups = [aws_security_group.alb.id]
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.example-loadbalancer.arn
  port = 80
  protocol = "HTTP"
  # By default, retun a simple 404 page
  default_action {
      type = "fixed-response"
      fixed_response {
          content_type = "text/plain"
          message_body = "404: Page Not Found"
          status_code = 404
      }
  }
}
resource "aws_security_group" "alb" {
  name = "terraform-example-alb"

  #Allow inbound HTTP requests 
  ingress {
      from_port = 80
      to_port = 80
      protocol = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
  }

  #Allow all outbound requests
  egress {
      from_port = 0
      to_port = 0
      protocol = "-1"
      cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_lb_target_group" "asg" {
  name = "terraform-asg-example"
  port = var.server_port
  protocol = "HTTP"
  vpc_id = data.aws_vpc.default.id

    health_check {
        path = "/"
        protocol = "HTTP"
        matcher = "200"
        interval = 15
        timeout = 3
        healthy_threshold = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "asg" {
  listener_arn = aws_lb_listener.http.arn
  priority = 100

  condition {
      field = "path-pattern"
      values = ["*"]
  }

  action {
      type = "forward"
      target_group_arn = aws_lb_target_group.asg.arn
  }
}