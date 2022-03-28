terraform {
  required_providers {
      aws = {
          source = "hashicorp/aws"
          version = "4.6.0"
      }
  }
}

provider "aws" {
  region = "us-east-1"
  shared_credentials_files = ["~/.aws/credentials"]
}

resource "aws_vpc" "TFD1-VPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
      Name = "Terraform-Demo-1-VPC"
  }
}

resource "aws_internet_gateway" "TFD1-Gateway" {
  vpc_id = aws_vpc.TFD1-VPC.id

  tags = {
      Name = "TFD1-Internet-Gateway"
  }
}

resource "aws_route_table" "TFD1-Route-Table" {
  vpc_id = aws_vpc.TFD1-VPC.id

  tags = {
      Name = "TFD1-Route-Table"
  }
}

resource "aws_route" "TFD1-Route-ipv4" {
  route_table_id = aws_internet_gateway.TFD1-Gateway.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.TFD1-Gateway.id
  depends_on = [aws_route_table.TFD1-Route-Table]
}

resource "aws_route" "TFD1-Route-ipv6" {
  route_table_id = aws_internet_gateway.TFD1-Gateway.id
  destination_ipv6_cidr_block = "::/0"
  gateway_id = aws_internet_gateway.TFD1-Gateway.id
  depends_on = [aws_route_table.TFD1-Route-Table]
}

resource "aws_subnet" "TFD1-Subnet-1" {
  vpc_id = aws_vpc.TFD1-VPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
      Name = "TFD1-Subnet-1"
  }
}

resource "aws_route_table_association" "TFD1-Route-Table-Association" {
  subnet_id = aws_subnet.TFD1-Subnet-1.id
  route_table_id = aws_route_table.TFD1-Route-Table.id
}

resource "aws_security_group" "TFD1-Security-Group" {
  name = "TFD1-Security-Group"
  description = "TFD1 Security Group"
  vpc_id = aws_vpc.TFD1-VPC.id

    tags = {
      Name = "TFD1-Security-Group"
  }
}

resource "aws_security_group_rule" "TFD1-Allow-HTTPS-Web" {
  description = "Allow Inbound HTTPS Web Traffic"
  type = "ingress"
  from_port = 443
  to_port = 443
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.TFD1-Security-Group.id
}

resource "aws_security_group_rule" "TFD1-Allow-HTTP-Web" {
  description = "Allow Inbound HTTP Web Traffic"
  type = "ingress"
  from_port = 80
  to_port = 80
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.TFD1-Security-Group.id
}

resource "aws_security_group_rule" "TFD1-Allow-SSH-Web" {
  description = "Allow Inbound SSH Web Traffic"
  type = "ingress"
  from_port = 22
  to_port = 22
  protocol = "tcp"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.TFD1-Security-Group.id
}

resource "aws_security_group_rule" "TFD1-Allow-Outbound-ipv6" {
  description = "Allow Outbound ipv6 Traffic"
  type = "egress"
  from_port = 0
  to_port = 0
  protocol = "-1"
  cidr_blocks = ["0.0.0.0/0"]
  ipv6_cidr_blocks = ["::/0"]
  security_group_id = aws_security_group.TFD1-Security-Group.id
}

resource "aws_network_interface" "TFD1-NIC" {
    subnet_id = aws_subnet.TFD1-Subnet-1.id
    private_ips = ["10.0.1.50"]
    security_groups = [aws_security_group.TFD1-Security-Group.id]
}

resource "aws_eip" "TFD1-EIP" {
  vpc = true
  network_interface = aws_network_interface.TFD1-NIC.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [
    aws_internet_gateway.TFD1-Gateway
  ]
}

resource "aws_instance" "TFD1-Instance" {
  # RHEL x86_64 Minecraft Server
  # Specs: t2.large, 2x vCPUs, 8.0 GiB RAM
  ami = "ami-0537d5849fff83412"
  instance_type = "t2.large"
  availability_zone = "us-east-1a"
  key_name = "TFD1"

  network_interface {
    network_interface_id = aws_network_interface.TFD1-NIC.id
    device_index = 0
  }
  tags = {
    Name = "Linux Server"
  }
}

