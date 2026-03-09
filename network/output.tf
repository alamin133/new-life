# 1. Announce the VPC ID
output "vpc_id_output" {
    description = "The ID of the vpc"
    value = aws_vpc.main_vpc.id 
}
# 2. Announce the Public Subnet ID
output "public_subnet_id_output" {
    description = "The ID of the public subnet "
    value = aws_subnet.public_sub.id
  
}
output "private_subnet_id_output" {
    description = "The ID of the private subnet"
    value = aws_subnet.private_sub.id
  
}