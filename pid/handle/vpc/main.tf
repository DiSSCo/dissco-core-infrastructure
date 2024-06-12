provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Handle"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Handle"
      Terraform   = "True"
    }
  }
}

module "handle-server-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name       = "handle-vpc"
  cidr       = "10.200.0.0/16"
  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  public_subnets = ["10.200.101.0/24", "10.200.102.0/24", "10.200.103.0/24"]
  create_igw = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "handle-server-sg" {
  name        = "handle-server-sg"
  description = "Handle server security group"
  vpc_id      = module.handle-server-vpc.vpc_id

  # ingress
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH access for Naturalis Eduroam"
    cidr_blocks = ["145.136.247.119/32"]
  }
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH Access for Naturalis Network"
    cidr_blocks = ["145.136.247.125/32"]
  }
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH Access for Sou Home"
    cidr_blocks = ["94.213.247.69/32"]
  }
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH Access for Sam Home"
    cidr_blocks = ["85.144.90.28/32"]
  }
  ingress {
    from_port   = 2641
    to_port     = 2641
    protocol    = "tcp"
    description = "TCP Access to Handle Server"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2641
    to_port     = 2641
    protocol    = "udp"
    description = "UDP Access to Handle Server"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    description = "HTTP Access to Handle Server"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "test/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_vpc_peering_connection" "database_peering" {
  peer_vpc_id = module.handle-server-vpc.vpc_id
  vpc_id      = data.terraform_remote_state.vpc-state.outputs.db-vpc-id-test
  auto_accept = true
  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "route_table_entry_kubernetes_private" {
  route_table_id            = module.handle-server-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.101.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_public" {
  route_table_id            = module.handle-server-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.101.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

