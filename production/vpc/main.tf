provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Production"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Core"
      Terraform   = "True"
    }
  }
}

resource "aws_eip" "k8s-eggress-ip" {
  domain = "vpc"
}

module "dissco-k8s-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name = "dissco-k8s-vpc-production"
  cidr = "10.0.0.0/16"

  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets = ["10.0.0.0/19", "10.0.32.0/19", "10.0.64.0/19"]
  private_subnets = ["10.0.96.0/19", "10.0.128.0/19", "10.0.160.0/19"]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  enable_dns_support = true

  # Ensure we get a single eggress NAT Gateway with fixed IP
  single_nat_gateway = true
  reuse_nat_ips = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.k8s-eggress-ip.*.id

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags = { Name = "dissco-k8s-network-acl-production" }
  manage_default_route_table    = true
  default_route_table_tags = { Name = "dissco-k8s-route-table-production" }
  manage_default_security_group = true
  default_security_group_tags = { Name = "dissco-k8s-sg-production" }
  private_subnet_tags = {
    "karpenter.sh/discovery" = "dissco-k8s-production"
  }
}

module "dissco-database-vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.16.0"

  name                                   = "dissco-database-vpc-production"
  cidr                                   = "10.1.0.0/16"
  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.1.1.0/24", "10.1.2.0/24", "10.1.3.0/24"]
  public_subnets = ["10.1.101.0/24", "10.1.102.0/24", "10.1.103.0/24"]
  database_subnets = ["10.1.201.0/24", "10.1.202.0/24", "10.1.203.0/24"]
  create_igw                             = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "dissco-database-sg" {
  name        = "dissco-database-sg-production"
  description = "Production database security group"
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
    description = "PostgreSQL access for Tom Office"
    cidr_blocks = ["81.172.128.113/32"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Tom Home"
    cidr_blocks = ["84.24.63.197/32"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Naturalis eduroam"
    cidr_blocks = ["145.136.247.119/32"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Naturalis EduVPN"
    cidr_blocks = ["145.90.236.12/32"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Naturalis Network"
    cidr_blocks = ["145.136.247.125/32"]
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Sou Home"
    cidr_blocks = ["94.213.247.69/32"]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "MongoDB access from within VPC"
    cidr_blocks = [module.dissco-database-vpc.vpc_cidr_block, module.dissco-k8s-vpc.vpc_cidr_block]
  }
}


# K8s/DB Peering
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
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_private" {
  route_table_id            = module.dissco-k8s-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_public" {
  route_table_id            = module.dissco-k8s-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.1.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}



data "terraform_remote_state" "handle-vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
     key    = "handle/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

data "terraform_remote_state" "doi-vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "doi/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}


# Handle / K8s Peering
/*
resource "aws_route" "route_table_entry_database_subnet_to_handle_pub" {
  route_table_id            = module.dissco-database-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.2.0.0/16"
  vpc_peering_connection_id = data.terraform_remote_state.handle-vpc-state.outputs.handle_peering_id
}

resource "aws_route" "route_table_entry_database_subnet_to_handle_priv" {
  route_table_id            = module.dissco-database-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.2.0.0/16"
  vpc_peering_connection_id = data.terraform_remote_state.handle-vpc-state.outputs.handle_peering_id
}*/

# DOI / K8s Peering
resource "aws_route" "route_table_entry_database_subnet_to_doi_pub" {
  route_table_id            = module.dissco-k8s-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.200.0.0/16"
  vpc_peering_connection_id = data.terraform_remote_state.doi-vpc-state.outputs.doi_peering_id
}

resource "aws_route" "route_table_entry_database_subnet_to_doi_priv" {
  route_table_id            = module.dissco-k8s-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.200.0.0/16"
  vpc_peering_connection_id = data.terraform_remote_state.doi-vpc-state.outputs.doi_peering_id
}


