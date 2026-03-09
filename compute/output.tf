# 1. Export the Public IP (The website address)
output "instance_public_ip" {
  description = "The public IP address of the web server"
  value       = aws_instance.web_server.public_ip
}

# 2. Export the Instance ID
output "instance_id" {
  description = "The unique ID of the EC2 instance"
  value       = aws_instance.web_server.id
}