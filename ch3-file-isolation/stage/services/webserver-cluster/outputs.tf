output "securitygroup-id" {
  description = "The ARN of the web-traffic security group"
  value = aws_security_group.web-traffic.id
}

# output "instance-id" {
#   description = "The ARN of the web-server instance"
#   value = aws_instance.webserver.id
# }

output "alb_dns_name" {
    value = aws_lb.example-loadbalancer.dns_name
    description = "The Domain Name of the Load Balancer"
}
