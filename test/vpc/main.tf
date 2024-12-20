provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Test"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Core"
      Terraform   = "True"
    }
  }
}

resource "aws_eip" "k8s-eggress-ip" {
  domain   = "vpc"
}

module "dissco-k8s-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "dissco-k8s-vpc-test"
  cidr = "10.100.0.0/16"

  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  public_subnets = ["10.100.0.0/19", "10.100.32.0/19", "10.100.64.0/19"]
  private_subnets = ["10.100.96.0/19", "10.100.128.0/19", "10.100.160.0/19"]

  enable_nat_gateway   = true
  create_igw           = true
  enable_dns_hostnames = true
  enable_dns_support   = true

  # Ensure we get a single eggress NAT Gateway with fixed IP
  single_nat_gateway   = true
  reuse_nat_ips       = true                    # <= Skip creation of EIPs for the NAT Gateways
  external_nat_ip_ids = aws_eip.k8s-eggress-ip.*.id

  # Manage so we can name
  manage_default_network_acl    = true
  default_network_acl_tags = { Name = "dissco-k8s-network-acl-test" }
  manage_default_route_table    = true
  default_route_table_tags = { Name = "dissco-k8s-route-table-test" }
  manage_default_security_group = true
  default_security_group_tags = { Name = "dissco-k8s-sg-test" }
  private_subnet_tags = {
    "karpenter.sh/discovery" = "dissco-k8s-test"
  }
}

module "dissco-database-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                                   = "dissco-database-vpc-test"
  cidr                                   = "10.101.0.0/16"
  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.101.1.0/24", "10.101.2.0/24", "10.101.3.0/24"]
  public_subnets = ["10.101.101.0/24", "10.101.102.0/24", "10.101.103.0/24"]
  database_subnets = ["10.101.201.0/24", "10.101.202.0/24", "10.101.203.0/24"]
  create_igw                             = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

data "terraform_remote_state" "handle-vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "handle/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_security_group" "dissco-database-sg" {
  name        = "dissco-database-sg-test"
  description = "Test database security group"
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
    description = "PostgreSQL access for Sou Home"
    cidr_blocks = ["94.213.247.69/32"]
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
    description = "Handle Server"
    cidr_blocks = ["18.130.232.162/32"]
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
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "MongoDB access for Handle Server"
    cidr_blocks = [data.terraform_remote_state.handle-vpc-state.outputs.handle_cidr_block]
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
  destination_cidr_block    = "10.100.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_private" {
  route_table_id            = module.dissco-k8s-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.101.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_public" {
  route_table_id            = module.dissco-k8s-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.101.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.database_peering.id
}

resource "aws_route" "route_table_entry_database_subnet_to_handle" {
  route_table_id            = module.dissco-database-vpc.database_route_table_ids[0]
  destination_cidr_block    = "10.2.0.0/16"
  vpc_peering_connection_id = data.terraform_remote_state.handle-vpc-state.outputs.handle_peering_id
}



