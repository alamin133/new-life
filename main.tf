terraform {
  # REMOTE STATE — Store tfstate file in S3 instead of local laptop
  backend "s3" {
    bucket = "new-life-dev-s3"    # Your existing S3 bucket name
    key    = "terraform.tfstate"  # Path/name of state file inside the bucket
    region = "us-east-1"          # Region where your S3 bucket lives
  }
  # Without this block → tfstate sits on your laptop (risky)
  # With this block    → tfstate safely stored in S3 (safe)

  required_providers {
    aws = {
      source  = "hashicorp/aws"  # Official AWS provider from Hashicorp
      version = "~> 5.0"         # Use any version 5.x (5.0, 5.1, 5.2 etc.)
    }
  }
}

provider "aws" {
  region = "us-east-1"  # All resources will be created in N. Virginia region
}

# 1. Call the Network Module (The City)
module "my_network" {
  source              = "./network"
  vpc_cidr            = var.vpc_cidr            # FROM tfvars
  public_subnet_cidr  = var.public_subnet_cidr  # FROM tfvars
  private_subnet_cidr = var.private_subnet_cidr # FROM tfvars
}

# 2. Call the Storage Module (The Warehouse + Security System)
module "my_storage" {
  source       = "./storage"
  project_name = var.project_name  # FROM tfvars
  environment  = var.environment   # FROM tfvars
}
# 3. Call the Compute Module (The Server)
module "my_compute" {
  source               = "./compute"
  vpc_id               = module.my_network.vpc_id_output
  subnet_id            = module.my_network.public_subnet_id_output
  instance_type        = var.instance_type         # FROM tfvars
  iam_instance_profile = module.my_storage.instance_profile_name
}
# 4. Final Report (Showing the IP to YOU)
output "final_web_ip" {
  value = module.my_compute.instance_public_ip  # Shows EC2 public IP after terraform apply
}