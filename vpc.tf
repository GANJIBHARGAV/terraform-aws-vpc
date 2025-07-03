# VPC roboshop-dev
resource "aws_vpc" "main" {
  cidr_block       = var.cidr
  instance_tenancy = "default"
  enable_dns_hostnames = true


  tags = merge(
    var.vpc_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"

    }
  )
}
# IGW roboshop-dev
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id  #associated with vpc

  tags = merge(
    var.igw_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"

    }
  )
}
#roboshop-dev-us-east-1a
#roboshop-dev-us-east-1b
resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  map_public_ip_on_launch = true

  tags = merge(
    var.public_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-public-${local.az_names[count.index]}"

    }
  )
}

resource "aws_subnet" "private" {
  count = length(var.private_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  tags = merge(
    var.private_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-private-${local.az_names[count.index]}"

    }
  )
}
#roboshop-database-subnet-1a
#roboshop-database-subnet-1b
resource "aws_subnet" "database" {
  count = length(var.database_subnet_cidrs)
  vpc_id     = aws_vpc.main.id
  cidr_block = var.database_subnet_cidrs[count.index]
  availability_zone = local.az_names[count.index]
  tags = merge(
    var.database_subnet_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-database-${local.az_names[count.index]}"

    }
  )
}

resource "aws_eip" "nat" {
  domain   = "vpc"
  tags = merge(
    var.eip_tags,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}"
    }
  )
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = merge(
    var.nat_tags,
    local.common_tags,
    {
       Name = "${var.project}-${var.environment}"
    }
  )

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.main]
}
#creating public aws route table 
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.public_route,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-public"
    }
  )
}
#creating private aws route table 
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.private_route,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-private"
    }
  )
}
#creating database aws route table 
resource "aws_route_table" "database" {
  vpc_id = aws_vpc.main.id

  tags = merge(
    var.database_route,
    local.common_tags,
    {
        Name = "${var.project}-${var.environment}-database"
    }
  )
}
# creating aws routes for public
resource "aws_route" "public" {
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.main.id
}
# creating aws routes for private
resource "aws_route" "private" {
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id
}
# creating aws routes for database
resource "aws_route" "database" {
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = "0.0.0.0/0"
  nat_gateway_id = aws_nat_gateway.main.id 
}
#creating public aws route table association
resource "aws_route_table_association" "public" {
    count = length(var.public_subnet_cidrs)
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}
#creating private  aws route table association 
resource "aws_route_table_association" "private" {
    count = length(var.private_subnet_cidrs)
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}
#creating database aws route table association
resource "aws_route_table_association" "database" {
    count = length(var.database_subnet_cidrs)
  subnet_id      = aws_subnet.database[count.index].id
  route_table_id = aws_route_table.database.id
}

resource "aws_route" "public_peering" {
  count = var.is_vpc_required ? 1 : 0
  route_table_id            = aws_route_table.public.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

resource "aws_route" "private_peering" {
  count = var.is_vpc_required ? 1 : 0
  route_table_id            = aws_route_table.private.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

resource "aws_route" "database_peering" {
  count = var.is_vpc_required ? 1 : 0
  route_table_id            = aws_route_table.database.id
  destination_cidr_block    = data.aws_vpc.default.cidr_block
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}

resource "aws_route" "default_peering" {
  count = var.is_vpc_required ? 1 : 0
  route_table_id            = data.aws_route_table.main.id
  destination_cidr_block    = var.cidr
  vpc_peering_connection_id = aws_vpc_peering_connection.default[count.index].id
}