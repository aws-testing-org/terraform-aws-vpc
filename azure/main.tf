data "aws_region" "current" {}

# Provision of VPC using IP Address management

resource "aws_vpc_ipam" "test" {
  operating_regions {
    region_name = data.aws_region.current.name
  }
}

resource "aws_vpc_ipam_pool" "test" {
  address_family = "ipv4"
  ipam_scope_id  = aws_vpc_ipam.test.private_default_scope_id
  locale         = data.aws_region.current.name
}

resource "aws_vpc_ipam_pool_cidr" "test" {
  ipam_pool_id = aws_vpc_ipam_pool.test.id
  cidr         = "10.0.0.0/16"
}

resource "aws_vpc" "test" {
  name = "demo-vpc"
  ipv4_ipam_pool_id   = aws_vpc_ipam_pool.test.id
  ipv4_netmask_length = 24
  depends_on = [
    aws_vpc_ipam_pool_cidr.test
  ]
}

# Provision of Subnet for the created VPC

resource "aws_subnet" "main" {
  vpc_id     = resource.aws_vpc.test.id
  cidr_block = cidrsubnet(resource.aws_vpc_ipam_pool_cidr.test.cidr, 8, 4)
}

# Provision of Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = resource.aws_vpc.test.id
}

# Creation of Route table

resource "aws_route_table" "example" {
  vpc_id = resource.aws_vpc.test.id
  route {
    cidr_block = resource.aws_vpc_ipam_pool_cidr.test.cidr
    gateway_id = resource.aws_internet_gateway.gw.id
  }
}

#Route table association to the created VPC

resource "aws_route_table_association" "test" {
  subnet_id      = resource.aws_subnet.main.id
  route_table_id = resource.aws_route_table.example.id
}
