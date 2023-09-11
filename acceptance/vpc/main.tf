provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Acceptance"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Core"
      Terraform   = "True"
    }
  }
}
module "dissco-k8s-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "dissco-k8s-vpc-acc"
  cidr = "10.50.0.0/16"

  azs             = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets  = ["10.50.0.0/19", "10.50.32.0/19", "10.50.64.0/19"]
  private_subnets = ["10.50.96.0/19", "10.50.128.0/19", "10.50.160.0/19"]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  enable_dns_support   = true
  single_nat_gateway   = true

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags      = { Name = "dissco-k8s-network-acl-acc" }
  manage_default_route_table    = true
  default_route_table_tags      = { Name = "dissco-k8s-route-table-acc" }
  manage_default_security_group = true
  default_security_group_tags   = { Name = "dissco-k8s-sg-acc" }
}

module "dissco-database-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                                   = "dissco-database-vpc-acc"
  cidr                                   = "10.51.0.0/16"
  azs                                    = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets                        = ["10.51.1.0/24", "10.51.2.0/24", "10.51.3.0/24"]
  public_subnets                         = ["10.51.101.0/24", "10.51.102.0/24", "10.51.103.0/24"]
  database_subnets                       = ["10.51.201.0/24", "10.51.202.0/24", "10.51.203.0/24"]
  create_igw                             = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "dissco-database-sg" {
  name        = "dissco-database-sg-acc"
  description = "Acceptance database security group"
  vpc_id      = module.dissco-database-vpc.vpc_id

  # ingress
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access from within VPC"
    cidr_blocks = [module.dissco-database-vpc.vpc_cidr_block, module.dissco-k8s-vpc.vpc_cidr_block]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Sam Home"
    cidr_blocks = ["87.208.51.107/32"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Naturalis eduroam"
    cidr_blocks = ["145.136.247.119/32"]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "MongoDB access from within VPC"
    cidr_blocks = [module.dissco-database-vpc.vpc_cidr_block, module.dissco-k8s-vpc.vpc_cidr_block]
  }
}

resource "aws_vpc_peering_connection" "database_peering" {
  peer_vpc_id = module.dissco-k8s-vpc.vpc_id
  vpc_id      = module.dissco-database-vpc.vpc_id
  auto_accept = true
  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "route_table_entry_database" {
  route_table_id            = module.dissco-database-vpc.database_route_table_ids[0]
  destination_cidr_block    = "10.50.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_private" {
  route_table_id            = module.dissco-k8s-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.51.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_public" {
  route_table_id            = module.dissco-k8s-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.51.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}