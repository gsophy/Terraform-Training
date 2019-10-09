output "address" {
    value = aws_db_instance.example.address
    description = "Connect to the database using this endpoint"
}

output "port" {
    value = aws_db_instance.example.port
    description ="Connect to the database using this port"
}

