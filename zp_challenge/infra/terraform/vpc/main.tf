## Declare the VPC resources

#################### Get availability zones ##########

data "aws_availability_zones" "available_zones" {}

###################### VPC creation ##################

resource "aws_vpc" "cb_vpc" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.environment} VPC"
    
  }
}

###################### Public subnet definitions ########################

resource "aws_subnet" "public" {
  count = var.public_count
  vpc_id = aws_vpc.cb_vpc.id
  cidr_block = var.public_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.environment} public subnet"
    Tier = "Public"
  }
}


###################### Private subnets for EKS #####################

resource "aws_subnet" "private" {
  count = var.private_count
  vpc_id = aws_vpc.cb_vpc.id
  cidr_block = var.private_subnet_cidrs[count.index]
  availability_zone = data.aws_availability_zones.available_zones.names[count.index]

  tags = {
    Name = "${var.environment} private subnet"
    Tier = "Private"
  }
}


#################### Internet Gateway #################

resource "aws_internet_gateway" "cb_gw" {
  vpc_id = aws_vpc.cb_vpc.id
}

################### Elastic Ip for nat gateway ###########
resource "aws_eip" "nat" {
  vpc = true
}

################### Nat gateway ###########################
data "aws_subnet_ids" "public_subs" {
  vpc_id = aws_vpc.cb_vpc.id
  tags = {
    Tier = "Public"
  }
  depends_on = [aws_vpc.cb_vpc, aws_subnet.public]
}

resource "random_shuffle" "nat_subnet" {
  input = data.aws_subnet_ids.public_subs.ids
  result_count = 1
}

resource "aws_nat_gateway" "nat_gw" {
  allocation_id = aws_eip.nat.id
  subnet_id     = random_shuffle.nat_subnet.result.0
  depends_on = [aws_internet_gateway.cb_gw]

  tags = {
    Name = "${var.environment} NAT_private_subnets"
  }
}

################ Route table definitions ####################

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cb_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.cb_gw.id
  }

  tags = {
    Name = "${var.environment} Public route table"
  }
}

resource "aws_route_table_association" "public_association" {
  count          = length(aws_subnet.public)
  subnet_id      = aws_subnet.public.*.id[count.index]
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cb_vpc.id
 
  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat_gw.id  
  }

  tags = {
    Name = "${var.environment} Private route table"
  }
}

resource "aws_route_table_association" "private_association" {
  count = length(aws_subnet.private)
  subnet_id = aws_subnet.private.*.id[count.index]
  route_table_id  = aws_route_table.private.id
}

resource "aws_security_group" "bastion" {
  name        = "Bastion"
  description = "Bastion SecurityGroup"
  vpc_id      = aws_vpc.cb_vpc.id

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }
  ingress {
    description = "SOCKS5"
    from_port   = 1080
    to_port     = 1080
    protocol    = "tcp"
    cidr_blocks = [var.access_ip]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Bastion"
  }
}


resource "aws_security_group" "load_balancer" {
  name        = "ALB-${var.environment}"
  description = "Security group for ECS load balancer"
  vpc_id      = aws_vpc.cb_vpc.id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ALB"
  }
}


resource "aws_security_group" "generic" {
  name        = "Generic"
  description = "Generic SecurityGroup for all instances"
  vpc_id      = aws_vpc.cb_vpc.id

  ingress {
    description = "VPC traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ var.vpc_cidr ]
  }

  ingress {
    description = "alb traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [ aws_security_group.load_balancer.id ]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Generic"
  }
}


resource "aws_security_group" "rds" {
  name        = "RDS"
  description = "RDS Security group"
  vpc_id      = aws_vpc.cb_vpc.id

  ingress {
    description = "VPC traffic"
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = [ var.vpc_cidr ]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "RDS"
  }
}

