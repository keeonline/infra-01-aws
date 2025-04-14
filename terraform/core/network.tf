data "aws_availability_zones" "available" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name    = "${var.infra_environment}-vpc"
    # Created = "${timestamp()}"
  }
}

# Create public and private subnets in the VPC

resource "aws_subnet" "public" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, (0 + (16 * count.index)))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name    = "${var.infra_environment}-subnet-public-${count.index}"
    Public = "yes"
    # Created = "${timestamp()}"
  }
}

resource "aws_subnet" "private" {
  count             = length(data.aws_availability_zones.available.names)
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, (48 + (16 * count.index)))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name    = "${var.infra_environment}-subnet-private-${count.index}"
    Public = "no"
    # Created = "${timestamp()}"
  }
}

# Create an internet gateway

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name    = "${var.infra_environment}-igw"
    # Created = "${timestamp()}"
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
    Name    = "${var.infra_environment}-rt-public"
    # Created = "${timestamp()}"
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
    Name    = "${var.infra_environment}-eip-ngw-${count.index}"
    # Created = "${timestamp()}"
  }
}

resource "aws_nat_gateway" "ngw" {
  count         = length(aws_subnet.public)
  allocation_id = aws_eip.ngw[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name    = "${var.infra_environment}-ngw-${count.index}"
    # Created = "${timestamp()}"
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
    Name    = "${var.infra_environment}-rt-private-${count.index}"
    # Created = "${timestamp()}"
  }
}

# Associate the private subnets with the route table for the NAT gateway in the same AZ

resource "aws_route_table_association" "private" {
  count          = length(aws_subnet.private)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private[count.index].id
}
