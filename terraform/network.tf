resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "${var.environment}-vpc"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.environment}-igw"
  }
}

# Loop up Availability Zones.
data "aws_availability_zones" "available" {}

locals {
    az_zone_count = length(aws_availability_zones.names)
}

# resource "aws_subnet" "public" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "${var.environment}-subnet-public"
#   }
# }

# Create public subnets.
resource "aws_subnet" "public" {
  count             = local.az_zone_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index}.0/24"
  availability_zone  = data.aws_availability_zones.available.names[count.index]
}

# Create private subnets.
resource "aws_subnet" "private" {
  count             = local.az_zone_count
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.${count.index+az_zone_count}.0/24"
  availability_zone  = data.aws_availability_zones.available.names[count.index]
}

# resource "aws_subnet" "private" {
#   vpc_id     = aws_vpc.main.id
#   cidr_block = "10.0.2.0/24"

#   tags = {
#     Name = "${var.environment}-subnet-private"
#   }
# }