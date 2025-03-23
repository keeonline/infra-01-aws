data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name        = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

# Create public and private subnets in the VPC

resource "aws_subnet" "public" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, (0 + (16 * count.index)))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-subnet-public-${count.index}"
    Environment = "${var.environment}"
    Public      = "yes"
  }
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, (48 + (16 * count.index)))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name        = "${var.environment}-subnet-private-${count.index}"
    Environment = "${var.environment}"
    Public      = "no"
  }
}

# Create an internet gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-igw"
    Environment = "${var.environment}"
  }
}

# Create a route table and add a route for public internet access 

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "${var.environment}-rt-public"
    Environment = "${var.environment}"
  }
}

# Associate each of the public subnets to the public route table to allow internet traffic

resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# Create a NAT gateway in each public subnet so that internet access from private subnets can be configured (later)

resource "aws_eip" "ngw" {
  count  = length(aws_subnet.public)
  domain = "vpc"

  tags = {
    Name        = "${var.environment}-eip-ngw-${count.index}"
    Environment = "${var.environment}"
  }
}

resource "aws_nat_gateway" "ngw" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name        = "${var.environment}-ngw-${count.index}"
    Environment = "${var.environment}"
  }
}

# Create a route table for the each of the NAT gateways and add a route for internet traffic

resource "aws_route_table" "private" {
  count  = length(aws_subnet.private)
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw[count.index].id
  }

  tags = {
    Name        = "${var.environment}-rt-private-${count.index}"
    Environment = "${var.environment}"
  }
}

# Associate the private subnets with the route table for the NAT gateway in the same AZ

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
