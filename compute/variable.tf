variable "vpc_id" {
    description = "The vpc where the security group will live"
    type = string

}
variable "subnet_id" {
    description = "the subnet where the ec2 instance will live"
    type = string
  
}
variable "instance_type" {
    description = "The size of the server"
    type = string
    default = "t2.micro"
}
variable "ami_id" {
  description = "The Amazon Machine Image ID"
  type        = string
  # This is the Amazon Linux 2023 AMI for us-east-1 (as of early 2026)
  default     = "ami-053b0d53c279acc90" 
}
variable "iam_instance_profile" {
  description = "IAM instance profile for EC2"
  type        = string
}