# 1. Create the VPC (The City Boundary)
resource "aws_vpc" "main_vpc"{
    cidr_block = var.vpc_cidr
    #ec2 runs on shared AWS hardware with other customers.
    instance_tenancy = "default"

    tags={
        Name="new-life-vpc"
    }
}
# 2. Create the Public Subnet (The Public District)
resource "aws_subnet" "public_sub"{
    vpc_id=aws_vpc.main_vpc.id
    cidr_block = var.public_subnet_cidr
    #EC2 launched in this subnet automatically gets a Public IP.
    map_public_ip_on_launch = true

    tags={
        Name="public-subnet"
    }
}
# 3. Create the Internet Gateway (The City Gate)

 resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main_vpc.id

    tags={
        Name="main-igw"
    }
   
 }
 # 4. Create a Route Table (The GPS/Map)

 resource "aws_route_table" "public_rt" {
    vpc_id = aws_vpc.main_vpc.id

   route{
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
   }
   tags = {
     Name="public-route-table"
   }
  
 }
 # 5. Connect Route Table to Subnet (Assigning the Map to the District)

 resource "aws_route_table_association" "public_assos" {
    subnet_id = aws_subnet.public_sub.id
    route_table_id = aws_route_table.public_rt.id
   
 }

# 6. Create the private subnet (The gated community)
resource "aws_subnet" "private_sub" {
    vpc_id = aws_vpc.main_vpc.id
    cidr_block = var.private_subnet_cidr
    map_public_ip_on_launch = false

    tags={
        Name="private-subnet"
    }
  
}
# 7. Create a Private Route Table (The "Internal-Only" Map)
resource "aws_route_table" "private_rt" {
    vpc_id = aws_vpc.main_vpc.id

    tags={
        Name="private-route-table"
    }
  
}
# 8. Connect Private Route Table to Private Subnet
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.private_sub.id
  route_table_id = aws_route_table.private_rt.id
}

