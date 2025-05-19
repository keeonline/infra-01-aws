data "aws_availability_zones" "available" {
  state = "available"
}

# Create the public subnets in the main VPC
resource "aws_subnet" "public" {
  count             = var.az_use_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, (0 + (16 * count.index)))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name       = "${var.infra_environment}-subnet-public-${count.index}"
    Visibility = "public"
  }
}

# Associate each of the public subnets to the public route table to allow internet traffic
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}


# Create the private subnets in the main VPC
resource "aws_subnet" "private" {
  count             = var.az_use_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(aws_vpc.main.cidr_block, 8, (48 + (16 * count.index)))
  availability_zone = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name       = "${var.infra_environment}-subnet-private-${count.index}"
    Visibility = "private"
  }
}



