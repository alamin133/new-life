variable "vpc_cidr" {
    description="The IP range for the entire VPC"
    type=string
    default = "10.0.0.0/16"
  
}
variable "public_subnet_cidr" {
    description = "The IP range for the public subnet"
    type = string
    default = "10.0.1.0/24"
  
}
variable "private_subnet_cidr" {
    description = "The IP range is for the private subnet"
    type=string
    default = "10.0.2.0/24"
  
}