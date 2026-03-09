# 1. Create a Security Group (The Firewall)
resource "aws_security_group" "web_sg" {
    name="web-server-sg"
    description = "Allow HTTP traffic"
    vpc_id = var.vpc_id # <--- Using the Variable from the network!
    
    ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allow anyone from the internet
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # Allow all outgoing traffic
    cidr_blocks = ["0.0.0.0/0"]
  }
    # allow SSH
    ingress {
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
    # allow Flask app
    ingress {
      from_port   = 5000
      to_port     = 5000
      protocol    = "tcp"
      cidr_blocks = ["0.0.0.0/0"]
    }
     egress {
      from_port   = 0
      to_port     = 0
      protocol    = "-1"
      cidr_blocks = ["0.0.0.0/0"]
    }

}
# 2. Create the EC2 Instance (The Server)
resource "aws_instance" "web_server" {
  ami           = var.ami_id     # <--- Using the variable
  instance_type = var.instance_type # <--- Using the variable
  subnet_id     = var.subnet_id   # <--- Placing it in the Public Subnet!

  vpc_security_group_ids = [aws_security_group.web_sg.id]
   iam_instance_profile   = var.iam_instance_profile 
   key_name               = "new-life-key"
  tags = {
    Name = "My-First-Terraform-Server"
    Environment = "Dev"
    Project = "New-Life"
  }
}