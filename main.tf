## Creating VPC
resource "aws_vpc" "cloudcomputing" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name = "CloudComputingProject"
  }
}
## Creating Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.cloudcomputing.id

  tags = {
    Name = "CloudComputingProject-igw"
  }
}

## Create AWS Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.cloudcomputing.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "cloudcomputing-public-subnet"
  }
}

## Create AWS Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id                  = aws_vpc.cloudcomputing.id
  cidr_block              = "10.0.2.0/24"
  availability_zone       = "us-east-2b"
  map_public_ip_on_launch = false

  tags = {
    Name = "cloudcomputing-private-subnet"
  }
}

## Create AWS Elastic Ip
resource "aws_eip" "natgateway_elastic_ip" {
  tags = {
    Name = "natgateway_elastic_ip_nat_gw"
  }
}

## Create NAT Gateway
resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.natgateway_elastic_ip.id
  subnet_id     = aws_subnet.public_subnet.id

  tags = {
    Name = "CloudComputingProject-nat-gw"
  }
  depends_on = [aws_internet_gateway.igw]
}

## Create Private Route Table
resource "aws_route_table" "private" {
  vpc_id = aws_vpc.cloudcomputing.id
  tags = {
    Name = "private-route-table"
  }
}

## Create Public Route Table

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.cloudcomputing.id
  tags = {
    Name = "public-route-table"
  }
}

## Updating Public InterNet Gateway Association
resource "aws_route" "public_internet_gateway" {
  route_table_id         = aws_route_table.public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.igw.id
}

## Updating  Nat Gateway Association
resource "aws_route" "private_nat_gateway" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat_gateway.id
}

## Associate of Public Route table for the subnet
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public.id
}


## Associate of Private Route table for the subnet
resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private.id
}

## Creation of AWS EC2 Security Group
resource "aws_security_group" "ec2instance" {
  name        = "ec2instanceflaskapp"
  description = "Allow Traffic through internet"
  vpc_id      = aws_vpc.cloudcomputing.id

  ingress {
    description = "Allow Traffic  from flask app"
    from_port   = 5003
    to_port     = 5003
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "allow ssh access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "Allow Traffic  from jenkins"
    from_port   = 8080
    to_port     = 8080
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "EC2 Instance Flask App"
  }
}

## Creating AWS EC2 Instance for jenkins
module "ec2_jenkins_instance" {
  source  = "terraform-aws-modules/ec2-instance/aws"
  version = "~> 3.0"

  name = "Jenkins"

  ami                         = "ami-089a545a9ed9893b6"
  instance_type               = "t2.micro"
  key_name                    = "user1"
  monitoring                  = true
  vpc_security_group_ids      = [aws_security_group.ec2instance.id]
  subnet_id                   = aws_subnet.public_subnet.id
  associate_public_ip_address = true
  user_data                   = file("jenkinsinit.sh")

  tags = {
    Terraform   = "true"
    Environment = "dev"
    Name        = "Jenkins"
  }
}
 