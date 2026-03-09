# dev.tfvars — All values for DEV environment

project_name        = "new-life"    # Project name used in storage module
environment         = "dev"         # Environment name used in storage module
vpc_cidr            = "10.0.0.0/16" # VPC address range for dev
public_subnet_cidr  = "10.0.1.0/24" # Public subnet range for dev
private_subnet_cidr = "10.0.2.0/24" # Private subnet range for dev
instance_type       = "t2.micro"    # EC2 size for dev