resource "aws_vpc" "main_vpc" {
  cidr_block = var.vpc_cidr


  tags = {
    Name = var.project_name
  }
}

resource "aws_internet_gateway" "gw_main_vp" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "${var.project_name}-gw"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_1
  availability_zone       = var.availability_zone_public_1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-1"
  }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.main_vpc.id
  cidr_block              = var.public_subnet_cidr_2
  availability_zone       = var.availability_zone_public_2
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-public-subnet-2"
  }
}

resource "aws_subnet" "private_subnet_1" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr_1
  availability_zone = var.availability_zone_private_1

  tags = {
    Name = "${var.project_name}-private-subnet-1"
  }
}

resource "aws_subnet" "private_subnet_2" {
  vpc_id            = aws_vpc.main_vpc.id
  cidr_block        = var.private_subnet_cidr_2
  availability_zone = var.availability_zone_private_2

  tags = {
    Name = "${var.project_name}-private-subnet-2"
  }
}
# route table 
resource "aws_route_table" "route_table_public_subnet" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw_main_vp.id
  }

  tags = {
    Name = "${var.project_name}-route-table-public-subnet"
  }
}

# Associate route table subnet-1
resource "aws_route_table_association" "associate_public_subnet_1" {
  subnet_id      = aws_subnet.public_subnet_1.id
  route_table_id = aws_route_table.route_table_public_subnet.id
}

# Associtae route table subnet-2
resource "aws_route_table_association" "associate_public_subnet_2" {
  subnet_id      = aws_subnet.public_subnet_2.id
  route_table_id = aws_route_table.route_table_public_subnet.id
}

# Elastic IP for NAT Gateway 
resource "aws_eip" "nat_eip" {
  domain = "vpc"

  tags = {
    Name = "${var.project_name}-nat-eip"
  }

  depends_on = [aws_internet_gateway.gw_main_vp]
}

# NAT Gateway - lives in public subnet 1, serves both private subnets 
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.public_subnet_1.id

  tags = {
    Name = "${var.project_name}-nat-gw"
  }

  depends_on = [aws_internet_gateway.gw_main_vp]
}

# Private Route Table - routes outbound traffic through NAT Gateway
resource "aws_route_table" "route_table_private" {
  vpc_id = aws_vpc.main_vpc.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }

  tags = {
    Name = "${var.project_name}-route-table-private"
  }
}

# Associate private route table with private subnet 1
resource "aws_route_table_association" "associate_private_subnet_1" {
  subnet_id      = aws_subnet.private-subnet-1.id
  route_table_id = aws_route_table.route_table_private.id
}

# Associate private route table with private subnet 2 
resource "aws_route_table_association" "associate_private_subnet_2" {
  subnet_id      = aws_subnet.private-subnet-2.id
  route_table_id = aws_route_table.route_table_private.id
}
