terraform{
    required_providers{
        aws = {
            source = "hashicorp/aws"
            version = "5.73.0"
        }
    }
}

provider "aws"{
    region = "us-east-1"
}
locals {
  aws_vpc_cidr = "192.168.1.0/24"   #defined cidr to create subnets under it ,I want to create subnet under every available zones .
}
#creating VPC 
resource "aws_vpc" "main" {
    cidr_block = local.aws_vpc_cidr
    enable_dns_hostnames = true
    enable_dns_support = true
    tags = {Name = "dev-vpc"}
}
#to get subnet in every available zone ,I need available zone and run for_each loop on them .I need data of availability zones.
data "aws_availability_zones" "main"{
    state = "available"
}
resource "aws_subnet" "main2" {
    for_each = toset(data.aws_availability_zones.main.names)
    vpc_id = aws_vpc.main.id
    availability_zone = each.value #either key or value
    cidr_block = cidrsubnet(local.aws_vpc_cidr,3, index(data.aws_availability_zones.main.names, each.value)) #(where is cidr coming from , how much will you add in 24 to get 27(we ), )
}

#creating internet gateway
resource "aws_internet_gateway" "main3" {
    vpc_id = aws_vpc.main.id
  
}
#creating route table
resource "aws_route_table" "main4" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.main3.id
    }
  
}
#adding this route table with each subnet
resource "aws_route_table_association" "main5" {
    for_each = aws_subnet.main2
    subnet_id = each.value.id 
    route_table_id = aws_route_table.main4.id
}
#creating security group to create EC2 instance
resource "aws_security_group" "main6" {
    vpc_id = aws_vpc.main.id
    ingress  {
        from_port = 0
        to_port =  0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress = {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
}
#providing ami id and giving ssh id
data "aws_ami" "main7" {
    most_recent = true
    filter {
      name   = "name"
      values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
    }
    owners = ["099720109477"]
}
resource "aws_key_pair" "main8" {
    key_name = "ubuntu"
    public_key = file("~/.ssh/ubuntu")
  
}
resource "aws_instance" "main9" {
    instance_type = "t2.micro"
    ami = data.aws_ami.main7.id
    secondary_private_ips = [aws_security_group.main6.id]
    key_name = aws_key_pair.main8.key_name
    associate_public_ip_address = true
    subnet_id = values(aws_subnet.main2)[1].id
}

#printing subnet,if subnet is not created this output will not print hence we need to create first then only it prints
/*output "subnet" {
    value = aws_subnet.main2
}*/
/*output "my_availability_zone" {
    value = data.aws_availability_zones.main.names
  
}*/ #this is to print availability zone in terminal for me to see
  



/*
# Define the required providers for this Terraform configuration
terraform {
    required_providers {
        aws = {  # Specify the AWS provider
            source  = "hashicorp/aws"  # Source of the AWS provider
            version = "5.73.0"          # Specify the version of the AWS provider to use
        }
    }
}

# Configure the AWS provider with specific settings
provider "aws" {
    region = "us-east-1"  # Set the AWS region where resources will be created
}

# Define local variables for use within this configuration
locals {
    aws_vpc_cidr = "192.168.1.0/24"  # Define the CIDR block for the VPC to create subnets under it
    # This CIDR allows for creating multiple subnets within the defined range.
}

# Create a Virtual Private Cloud (VPC)
resource "aws_vpc" "main" {
    cidr_block           = local.aws_vpc_cidr  # Use the defined CIDR block for the VPC
    enable_dns_hostnames = true                 # Enable DNS hostnames within the VPC
    enable_dns_support   = true                 # Enable DNS support for the VPC
    tags = { Name = "dev-vpc" }                 # Tag the VPC with a name for identification
}

# Fetch available availability zones in the specified region
data "aws_availability_zones" "main" {
    state = "available"  # Only consider availability zones that are currently available
}

# Create subnets in each available availability zone
resource "aws_subnet" "main2" {
    for_each = toset(data.aws_availability_zones.main.names)  # Iterate over each availability zone

    vpc_id              = aws_vpc.main.id                     # Associate each subnet with the created VPC
    availability_zone   = each.value                           # Set the availability zone for this subnet

    # Calculate CIDR block for each subnet based on the main VPC CIDR block
    cidr_block          = cidrsubnet(local.aws_vpc_cidr, 3, index(data.aws_availability_zones.main.names, each.value))
    # The cidrsubnet function is used to create subnets:
    # - The first argument is the base CIDR block (VPC CIDR).
    # - The second argument (3) indicates how many bits to add to create subnets (from /24 to /27).
    # - The third argument uses index to determine which subnet to create based on its position in the list of AZs.
}

/* 
Output block (commented out)
output "my_availability_zone" {
    value = data.aws_availability_zones.main.names  # Output the names of available availability zones for reference in terminal
}
*/

