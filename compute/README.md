# 🌱 New-Life Infrastructure Project
### A Complete Terraform Learning Guide — Written For Myself

---

## 📁 Project Structure

```
new-life/
├── main.tf              → Global entry point. Calls all modules and connects them together.
├── variables.tf         → Global shared variables (project_name, environment)
├── outputs.tf           → Global outputs (shows final IP after apply)
│
├── network/             → Everything about networking (VPC, subnets, routes)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── compute/             → Everything about the server (EC2, security group)
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
└── storage/             → Everything about storage and permissions (S3, IAM)
    ├── main.tf
    ├── variables.tf
    └── outputs.tf
```

---

## 🧠 Big Picture — How Everything Connects

```
NETWORK MODULE          STORAGE MODULE           COMPUTE MODULE
──────────────          ──────────────           ──────────────
Creates VPC        →    Creates S3 Bucket   →    Creates EC2
Creates Subnets         Creates IAM Policy        Uses VPC from network
Creates Routes          Creates IAM Role          Uses Subnet from network
Creates IGW             Creates Profile      →    Attaches Profile to EC2
       ↓                                                   ↓
  vpc_id, subnet_id ─────────────────────────→  EC2 lives inside VPC
                    instance_profile_name ──→    EC2 can talk to S3
```

---

## 🌐 MODULE 1 — Network (The City)

> Think of the network as a CITY. The VPC is the city boundary, subnets are neighborhoods, the internet gateway is the city gate, and route tables are road signs.

### `network/variables.tf`
```hcl
variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}
# vpc_cidr = "10.0.0.0/16"
# This means the city can have IP addresses from 10.0.0.0 to 10.0.255.255
# /16 means 65,536 possible addresses — a big city!

variable "public_subnet_cidr" {
  description = "CIDR block for public subnet"
  type        = string
}
# public_subnet_cidr = "10.0.1.0/24"
# This is the PUBLIC neighborhood — anyone from internet can reach it
# /24 means 256 possible addresses in this neighborhood

variable "private_subnet_cidr" {
  description = "CIDR block for private subnet"
  type        = string
}
# private_subnet_cidr = "10.0.2.0/24"
# This is the PRIVATE neighborhood — only internal traffic, no internet access
```

### `network/main.tf`
```hcl
# THE VPC — The entire city boundary
resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr
}
# Real world: Like drawing a fence around your city
# Everything inside this fence is YOUR network

# THE SUBNETS — Neighborhoods inside the city
resource "aws_subnet" "public_sub" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.public_subnet_cidr
}
# Real world: The public area of the city (like a shopping mall)
# EC2 lives here so the internet can reach it

resource "aws_subnet" "private_sub" {
  vpc_id     = aws_vpc.main_vpc.id
  cidr_block = var.private_subnet_cidr
}
# Real world: The private area of the city (like a bank vault)
# Databases live here — no direct internet access

# THE INTERNET GATEWAY — The city gate
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main_vpc.id
}
# Real world: The main entrance/exit of the city
# Without this, NOTHING can come in or go out from the internet

# THE ROUTE TABLES — Road signs
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"       # ALL traffic (0.0.0.0/0 means everyone)
    gateway_id = aws_internet_gateway.igw.id  # goes through the city gate
  }
}
# Real world: A sign that says "For ALL destinations → use the main gate"
# This is what makes the public subnet actually PUBLIC

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.main_vpc.id
  # No route to internet gateway — private stays private!
}
# Real world: No sign pointing to the city gate — you cannot leave or enter

# ROUTE TABLE ASSOCIATIONS — Connecting signs to neighborhoods
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_sub.id
  route_table_id = aws_route_table.public_rt.id
}
# Real world: Placing the PUBLIC road signs in the PUBLIC neighborhood

resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private_rt.id
}
# Real world: Placing the PRIVATE road signs in the PRIVATE neighborhood
```

### `network/outputs.tf`
```hcl
output "vpc_id_output" {
  value = aws_vpc.main_vpc.id
}
# Why? Because compute module needs to know WHICH city to put the EC2 in
# Without this, compute module cannot find the VPC

output "public_subnet_id_output" {
  value = aws_subnet.public_sub.id
}
# Why? Because compute module needs to know WHICH neighborhood to put EC2 in
# We use public subnet so EC2 gets a public IP and internet can reach it
```

---

## 🗄️ MODULE 2 — Storage (The Warehouse + Security System)

> Think of storage as a WAREHOUSE with a SECURITY SYSTEM. S3 is the warehouse. IAM Policy is the list of allowed actions. IAM Role is the job title. Instance Profile is the ID card. EC2 is the worker.

### `storage/variables.tf`
```hcl
variable "project_name" {
  description = "Name of the project"
  type        = string
}
# Used to name all resources consistently
# Example: "new-life"

variable "environment" {
  description = "Environment name"
  type        = string
}
# Used to separate dev from prod resources
# Example: "dev" or "prod"
```

### `storage/main.tf`
```hcl
# STEP 1 — THE S3 BUCKET (The Warehouse)
resource "aws_s3_bucket" "bucket" {
  bucket = "${var.project_name}-${var.environment}-s3"
}
# Real world: A warehouse where you store files
# Name becomes: "new-life-dev-s3"
# ${var.project_name} = "new-life"
# ${var.environment}  = "dev"
# Combined:           = "new-life-dev-s3"


# STEP 2 — THE IAM POLICY (The List of Allowed Actions)
resource "aws_iam_policy" "s3_policy" {
  name = "${var.project_name}-${var.environment}-s3-policy"
  # Name becomes: "new-life-dev-s3-policy"

  policy = jsonencode({
    Version = "2012-10-17"      # AWS policy version format — always this date
    Statement = [
      {
        Effect = "Allow"        # ALLOW these actions (can also be "Deny")
        Action = [
          "s3:PutObject",       # Permission to UPLOAD files to S3
          "s3:DeleteObject"     # Permission to DELETE files from S3
        ]
        Resource = "${aws_s3_bucket.bucket.arn}/*"
        # arn = Amazon Resource Name — unique ID for the S3 bucket
        # /* means ALL files inside the bucket
        # Example: arn:aws:s3:::new-life-dev-s3/*
      }
    ]
  })
}
# Real world: A rulebook that says:
# "You are ALLOWED to upload files and delete files from new-life-dev-s3"
# Note: This policy alone does NOTHING — it must be attached to a role


# STEP 3 — THE IAM ROLE (The Job Title)
resource "aws_iam_role" "ec2_role" {
  name = "${var.project_name}-${var.environment}-ec2-role"
  # Name becomes: "new-life-dev-ec2-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "ec2.amazonaws.com"   # Only EC2 can use this role
        }
        Action = "sts:AssumeRole"         # EC2 is allowed to "wear" this role
      }
    ]
  })
}
# Real world: A job title called "Warehouse Worker"
# assume_role_policy = "Who is allowed to use this role?"
# Answer: Only EC2 service (ec2.amazonaws.com)
# sts:AssumeRole = "take on this identity"


# STEP 4 — ATTACH POLICY TO ROLE (Give the Worker the Rulebook)
resource "aws_iam_role_policy_attachment" "attach" {
  role       = aws_iam_role.ec2_role.name        # The job title
  policy_arn = aws_iam_policy.s3_policy.arn      # The rulebook
}
# Real world: Giving the "Warehouse Worker" job title the S3 rulebook
# Now the role HAS the permissions defined in the policy
# Without this step: role exists but has NO permissions


# STEP 5 — THE INSTANCE PROFILE (The ID Card)
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-${var.environment}-ec2-profile"
  # Name becomes: "new-life-dev-ec2-profile"
  role = aws_iam_role.ec2_role.name   # Which role does this ID card represent?
}
# Real world: An ID card that proves "I am a Warehouse Worker"
# EC2 cannot directly use an IAM Role — it needs an Instance Profile wrapper
# Think of it as: Role = job title, Instance Profile = physical ID card
# Without this: EC2 cannot be linked to the IAM Role
```

### `storage/outputs.tf`
```hcl
output "instance_profile_name" {
  value = aws_iam_instance_profile.ec2_profile.name
}
# Why? Because compute module needs this name to attach to EC2
# Without this output, the profile name is stuck INSIDE storage module
# The output is like an "exit door" for the value
# Compute module accesses it as: module.my_storage.instance_profile_name
```

---

## 💻 MODULE 3 — Compute (The Server)

> Think of compute as the WORKER. The security group is the bodyguard. The EC2 is the actual worker doing the job.

### `compute/variables.tf`
```hcl
variable "vpc_id" {
  description = "The vpc where the security group will live"
  type        = string
}
# Received FROM network module
# Tells EC2 which VPC to live in

variable "subnet_id" {
  description = "The subnet where the EC2 instance will live"
  type        = string
}
# Received FROM network module
# Tells EC2 which subnet (neighborhood) to live in

variable "instance_type" {
  description = "The size of the server"
  type        = string
  default     = "t2.micro"
}
# t2.micro = smallest and cheapest EC2 — good for learning
# Other sizes: t2.small, t2.medium, t3.large etc.

variable "ami_id" {
  description = "The Amazon Machine Image ID"
  type        = string
  default     = "ami-053b0d53c279acc90"
}
# AMI = the operating system image (like an ISO file)
# This specific AMI = Amazon Linux 2023 in us-east-1 region
# Different regions have different AMI IDs for same OS

variable "iam_instance_profile" {
  description = "IAM instance profile for EC2"
  type        = string
}
# Received FROM storage module
# This is the ID card that gives EC2 permission to access S3
```

### `compute/main.tf`
```hcl
# THE SECURITY GROUP (The Bodyguard / Firewall)
resource "aws_security_group" "web_sg" {
  name        = "web-server-sg"
  description = "Allow HTTP traffic"
  vpc_id      = var.vpc_id    # Which VPC does this firewall protect?

  ingress {                   # INCOMING traffic rules
    from_port   = 80          # Port 80 = HTTP (websites)
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]  # Allow from ANYWHERE on the internet
  }
  # Real world: "Allow anyone to knock on door number 80 (HTTP)"
  # If you wanted SSH access you would add port 22 here

  egress {                    # OUTGOING traffic rules
    from_port   = 0           # Port 0 = all ports
    to_port     = 0
    protocol    = "-1"        # -1 = all protocols
    cidr_blocks = ["0.0.0.0/0"]  # Allow to go ANYWHERE
  }
  # Real world: "Allow EC2 to talk to anyone on the internet"
  # This is needed so EC2 can download updates, talk to S3, etc.
}


# THE EC2 INSTANCE (The Actual Server)
resource "aws_instance" "web_server" {
  ami                    = var.ami_id           # Which operating system?
  instance_type          = var.instance_type    # How powerful? (t2.micro)
  subnet_id              = var.subnet_id        # Which neighborhood?
  vpc_security_group_ids = [aws_security_group.web_sg.id]  # Which bodyguard?
  iam_instance_profile   = var.iam_instance_profile        # Which ID card?
  # iam_instance_profile is the KEY LINE that connects EC2 to S3 permissions!

  tags = {
    Name        = "My-First-Terraform-Server"
    Environment = "Dev"
    Project     = "New-Life"
  }
  # Tags are just labels — they help you identify resources in AWS Console
  # They do NOT affect how the resource works
}
```

### `compute/outputs.tf`
```hcl
output "instance_public_ip" {
  value = aws_instance.web_server.public_ip
}
# Why? Because global main.tf wants to show us the IP at the end
# After terraform apply you see: final_web_ip = "52.90.55.238"
# Without this output, the IP is stuck INSIDE compute module
```

---

## 🌍 GLOBAL — main.tf (The Master Controller)

```hcl
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"    # Use any version 5.x (5.0, 5.1, 5.2 etc.)
    }
  }
}
# This block tells Terraform: "I need the AWS plugin to talk to AWS"

provider "aws" {
  region = "us-east-1"
}
# This tells Terraform: "Connect to AWS in the us-east-1 region (N. Virginia)"
# All resources will be created in this region


# MODULE 1 — Build the network first
module "my_network" {
  source              = "./network"       # Where is the module code?
  vpc_cidr            = "10.0.0.0/16"    # Pass value into network/variables.tf
  public_subnet_cidr  = "10.0.1.0/24"   # Pass value into network/variables.tf
  private_subnet_cidr = "10.0.2.0/24"   # Pass value into network/variables.tf
}
# Think of this as: "Hey network module, here are your instructions, go build!"


# MODULE 2 — Build the storage and permissions
module "my_storage" {
  source       = "./storage"        # Where is the module code?
  project_name = "new-life"         # Pass value into storage/variables.tf
  environment  = "dev"              # Pass value into storage/variables.tf
}
# Think of this as: "Hey storage module, build S3 and IAM for project new-life"


# MODULE 3 — Build the compute last (needs values from network and storage)
module "my_compute" {
  source               = "./compute"     # Where is the module code?
  vpc_id               = module.my_network.vpc_id_output            # FROM network
  subnet_id            = module.my_network.public_subnet_id_output  # FROM network
  instance_type        = "t2.micro"
  iam_instance_profile = module.my_storage.instance_profile_name    # FROM storage
}
# module.my_network.vpc_id_output means:
# "Go to my_network module, find the output named vpc_id_output, use its value"
# This is how modules TALK to each other — through outputs and inputs


# FINAL OUTPUT — Show the IP address after everything is built
output "final_web_ip" {
  value = module.my_compute.instance_public_ip
}
# After terraform apply finishes you will see:
# Outputs:
# final_web_ip = "52.90.55.238"
```

---

## 🔐 How EC2 Connects to S3 — Full Chain Explained

```
┌─────────────────────────────────────────────────────────────┐
│                                                             │
│   EC2 Instance                                              │
│   └── iam_instance_profile = "new-life-dev-ec2-profile"    │
│         │                                                   │
│         ▼                                                   │
│   Instance Profile (new-life-dev-ec2-profile)               │
│   └── role = "new-life-dev-ec2-role"                        │
│         │                                                   │
│         ▼                                                   │
│   IAM Role (new-life-dev-ec2-role)                          │
│   └── attached policy = "new-life-dev-s3-policy"           │
│         │                                                   │
│         ▼                                                   │
│   IAM Policy (new-life-dev-s3-policy)                       │
│   └── Allow: s3:PutObject, s3:DeleteObject                  │
│         │                                                   │
│         ▼                                                   │
│   S3 Bucket (new-life-dev-s3)  ✅ EC2 can now upload/delete │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

**Why each piece is needed:**
- **S3 Bucket** → The actual place to store files. Without it, nothing to upload to.
- **IAM Policy** → Defines WHAT actions are allowed. Without it, role has no permissions.
- **IAM Role** → The identity that EC2 takes on. Without it, no identity to attach permissions to.
- **Policy Attachment** → Links policy to role. Without it, role exists but has zero permissions.
- **Instance Profile** → The bridge between role and EC2. Without it, EC2 cannot use the role.
- **iam_instance_profile on EC2** → Actually attaches the profile. Without it, EC2 never gets the identity.

---

## ⚙️ Terraform Commands

```bash
# Initialize project — downloads AWS provider plugin
# Run this ONCE at the start or when you add a new module
terraform init

# Preview what will be created/changed/destroyed
# ALWAYS run this before apply to check what will happen
terraform plan

# Actually create the infrastructure in AWS
terraform apply

# Show current state of all resources
terraform state list

# Destroy ALL resources (careful! deletes everything)
terraform destroy
```

---

## 🔍 How to Verify Everything is Working (AWS CLI)

```bash
# Check S3 bucket was created
aws s3 ls | findstr new-life

# Check IAM role was created
aws iam get-role --role-name new-life-dev-ec2-role

# Check policy is attached to role
aws iam list-attached-role-policies --role-name new-life-dev-ec2-role

# Check instance profile was created
aws iam get-instance-profile --instance-profile-name new-life-dev-ec2-profile

# Check EC2 has instance profile attached
aws ec2 describe-instances --query "Reservations[*].Instances[*].{ID:InstanceId,Profile:IamInstanceProfile.Arn}" --output table

# Upload a test file to S3
echo "hello s3" > test.txt
aws s3 cp test.txt s3://new-life-dev-s3/

# List files in bucket
aws s3 ls s3://new-life-dev-s3/

# Delete the test file
aws s3 rm s3://new-life-dev-s3/test.txt
```

---

## 💡 Key Concepts to Remember

| Concept | Simple Explanation |
|---|---|
| VPC | Your private city in AWS cloud |
| Subnet | A neighborhood inside the city |
| Internet Gateway | The city gate to the internet |
| Route Table | Road signs that direct traffic |
| Security Group | A firewall/bodyguard for EC2 |
| EC2 | The actual server/computer |
| S3 | Cloud storage (like a hard drive in the cloud) |
| IAM Policy | A rulebook of allowed actions |
| IAM Role | A job title with a set of permissions |
| Instance Profile | An ID card that links role to EC2 |
| Module | A reusable folder of Terraform code |
| Output | An exit door for values between modules |
| Variable | An input door for values into modules |

---

## 🧩 Why Modular Structure?

```
WITHOUT modules (everything in one file):
main.tf = 500 lines of mixed network + compute + storage code
→ Hard to read
→ Hard to fix bugs
→ Cannot reuse code

WITH modules (separated by responsibility):
network/  = only network code    (clean, focused)
compute/  = only compute code    (clean, focused)
storage/  = only storage code    (clean, focused)
→ Easy to read
→ Easy to fix bugs
→ Can reuse modules in other projects
```

---

*This project was built step by step to understand AWS infrastructure using Terraform.*
*Every resource has a purpose. Every connection has a reason.*