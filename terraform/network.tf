resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support = true

  tags = {
    Name = "${var.environment}-vpc"
    Environment = "${var.environment}"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
    Environment = "${var.environment}"
  }
}

data "aws_availability_zones" "available" {}

locals {
    az_zone_count = length(data.aws_availability_zones.available.names)
}

resource "aws_subnet" "public" {
  count             = local.az_zone_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone  = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-subnet-public-${count.index}"
    Environment = "${var.environment}"
  }
}

resource "aws_subnet" "private" {
  count             = local.az_zone_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index+local.az_zone_count}.0/24"
  availability_zone  = data.aws_availability_zones.available.names[count.index]

  tags = {
    Name = "${var.environment}-subnet-private-${count.index}"
    Environment = "${var.environment}"
  }
}



# Routing tables to route traffic for Public Subnet
resource "aws_route_table" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name        = "${var.environment}-route-table-public"
    Environment = "${var.environment}"
  }
}

resource "aws_main_route_table_association" "main" {
  vpc_id         = aws_vpc.main.id
  route_table_id = aws_route_table.main.id
}

# Route table associations for Public subnets
resource "aws_route_table_association" "public" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.main.id
}

resource "aws_route" "local" {
  route_table_id            = aws_route_table.main.id
  destination_cidr_block    = aws_vpc.main.cidr_block
  gateway_id = "local"
}

resource "aws_route" "igw" {
  route_table_id            = aws_route_table.main.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw.id
}