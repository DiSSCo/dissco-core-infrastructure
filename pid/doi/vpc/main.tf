provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "DOI"
      Owner       = "DiSSCo"
      Project     = "DiSSCo DOI"
      Terraform   = "True"
    }
  }
}

module "doi-vpc" {
  source                                 = "terraform-aws-modules/vpc/aws"
  name                                   = "doi-vpc"
  cidr                                   = "10.200.0.0/16"
  azs = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  public_subnets = ["10.200.101.0/24", "10.200.102.0/24", "10.200.103.0/24"]
  database_subnets = ["10.200.201.0/24", "10.200.202.0/24", "10.200.203.0/24"]
  create_igw                             = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "doi-server-sg" {
  name        = "doi-server-sg"
  description = "DOI server security group"
  vpc_id      = module.doi-vpc.vpc_id

  # ingress
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH access for Naturalis Eduroam"
    cidr_blocks = ["145.136.247.119/32"]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "Mongodb access from EduVPN"
    cidr_blocks = ["145.90.236.23/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH Access for Naturalis Network"
    cidr_blocks = ["145.136.247.125/32"]
  }
  ingress {
    from_port   = 2641
    to_port     = 2641
    protocol    = "tcp"
    description = "TCP Access to DOI Server"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 2641
    to_port     = 2641
    protocol    = "udp"
    description = "UDP Access to DOI Server"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    description = "HTTP Access to DOI Server"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP Access to DOI API"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS Access to DOI API"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}


resource "aws_security_group" "doi-database-sg" {
  name        = "doi-database-sg"
  description = "DOI database security group"

  ingress {
    cidr_blocks = [
      "10.200.0.0/16",
    ]
    description = "PostgreSQL access from within VPC"
    from_port   = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol    = "tcp"
    security_groups = []
    self        = false
    to_port     = 5432
  }
  ingress {
    cidr_blocks = [
      "145.136.247.119/32",
    ]
    description = "PostgreSQL access for Naturalis eduroam"
    from_port   = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol    = "tcp"
    security_groups = []
    self        = false
    to_port     = 5432
  }
  ingress {
    cidr_blocks = [
      "145.136.247.125/32",
    ]
    description = "PostgreSQL access for Naturalis Network"
    from_port   = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol    = "tcp"
    security_groups = []
    self        = false
    to_port     = 5432
  }
  ingress {
    cidr_blocks = [
      "93.102.85.38/32",
    ]
    description = "Sou Temp"
    from_port   = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol    = "tcp"
    security_groups = []
    self        = false
    to_port     = 5432
  }
  ingress {
    cidr_blocks = [
      "94.213.247.69/32",
    ]
    description = "Sou Home"
    from_port   = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol    = "tcp"
    security_groups = []
    self        = false
    to_port     = 5432
  }
  ingress {
    cidr_blocks = []
    description = "Sou Temp"
    from_port   = 5432
    ipv6_cidr_blocks = []
    prefix_list_ids = []
    protocol    = "tcp"
    security_groups = []
    self        = false
    to_port     = 5432
  }
}

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "production/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_vpc_peering_connection" "doi_k8s_peering" {
  peer_vpc_id = module.doi-vpc.vpc_id
  vpc_id      = data.terraform_remote_state.vpc-state.outputs.k8s-vpc-id
  auto_accept = true
  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

resource "aws_route" "route_table_entry_kubernetes_public" {
  route_table_id            = module.doi-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.doi_k8s_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_database" {
  route_table_id            = module.doi-vpc.database_route_table_ids[0]
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.doi_k8s_peering.id
}

resource "aws_route" "route_table_entry_kubernetes_private" {
  route_table_id            = module.doi-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.doi_k8s_peering.id
}