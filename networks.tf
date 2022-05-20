
# AWS VPC Infrastructure

# us-east-1 VPC
resource "aws_vpc" "vpc_east" {
  provider = aws.region_master
  cidr_block = "10.0.0.0/16"

  tags = {
    "Name" = "VPC East"
  }
}

# us-west-2 VPC
resource "aws_vpc" "vpc_west" {
    provider = aws.region_worker
  cidr_block = "192.168.0.0/16"

  tags = {
    "Name" = "VPC West"
  }
}

resource "aws_subnet" "east_subnet_1" {
    provider = aws.region_master
  vpc_id = aws_vpc.vpc_east.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "east_subnet_2" {
    provider = aws.region_master
  vpc_id = aws_vpc.vpc_east.id
  cidr_block = "10.0.2.0/24"
}

resource "aws_subnet" "west_subnet" {
    provider = aws.region_worker
  vpc_id = aws_vpc.vpc_west.id
  cidr_block = "192.168.1.0/24"
}

# AWS Internet Gateway Infrastructure
resource "aws_internet_gateway" "east_ig" {
  vpc_id = aws_vpc.vpc_east.id

  tags = {
    "Name" = "Internet Gateway East"
  }
}

resource "aws_internet_gateway" "west_ig" {
    provider = aws.region_worker
  vpc_id = aws_vpc.vpc_west.id

  tags = {
    "Name" = "Internet Gateway West"
  }
}



# Route Table Infrastructure
resource "aws_route_table" "east_rt" {
    provider = aws.region_master
  vpc_id = aws_vpc.vpc_east.id

  route  {
      cidr_block = "0.0.0.0/0"
      gatewy_id = aws_internet_gateway.east_ig.id
  }

  route  {
    cidr_block = "192.168.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }
  lifecycle {
    ignore_changes = all
  }

  tags = {
    "Name" = "Master-Region-RT"
  }
}

resource "aws_route_table" "west_rt" {
  provider = aws.region_worker  
  vpc_id = aws_vpc.vpc_west.id

  route {
      cidr_block = "0.0.0.0./0"
      gateway_id = aws_internet_gateway.west_ig.id
  }

  route {
      cidr_block = "10.0.1.0/24"
      vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    "Name" = "Worker-Region-RT"
  }
}



# VPC Peering Infrastructure
resource "aws_vpc_peering_connection_accepter" "name" {
  provider = aws.region_worker
  vpc_peering_connection_id = aws_vpc_peering_connection.useast1-uswest2.id
  auto_accept = true
}


resource "aws_vpc_peering_connection" "useast1-uswest2" {
  provider = aws.region_master
  peer_vpc_id = aws_vpc.vpc_west.id
  vpc_id = aws_vpc.vpc_west.id
  #auto_accept = true
  peer_region = var.region_worker
}

# Overwrite default route table of VPC(MAster with our route table entries
resource "aws_main_route_table_association" "set_master_default_rt_assoc" {
    provider = aws.region_master
    vpc_id = aws_vpc.vpc_east.id  
    route_table_id = aws_route_table.east_rt.id
}