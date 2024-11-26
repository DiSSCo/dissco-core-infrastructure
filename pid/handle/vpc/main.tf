provider "aws" {
  region = "eu-north-1"
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

  name                = "handle-vpc"
  cidr                = "10.2.0.0/16"
  azs                 = ["eu-north-1a", "eu-north-1b", "eu-north-1c"]
  private_subnets     = ["10.2.1.0/24", "10.2.2.0/24", "10.2.3.0/24"]
  public_subnets      = ["10.2.101.0/24", "10.2.102.0/24", "10.2.103.0/24"]

  create_igw           = true
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
    description = "SSH Access for Sou Temp"
    cidr_blocks = ["203.109.214.6/32"]
  }
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH Access for Sam Home"
    cidr_blocks = ["85.144.90.28/32"]
  }
  ingress {
    from_port   = 0
    to_port     = 22
    protocol    = "tcp"
    description = "SSH Access for EduVPN"
    cidr_blocks = ["145.90.236.12/32"]
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
    description = "HTTP Access to Handle VPC"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "production/vpc/terraform.tfstate"
    region = "eu-north-1"
  }
}

# Connect Handle Server to the K8s VPC
resource "aws_vpc_peering_connection" "handle_to_k8s_peering" {
  peer_vpc_id = module.handle-server-vpc.vpc_id
  vpc_id      = data.terraform_remote_state.vpc-state.outputs.k8s-vpc-id
  auto_accept = true
  requester {
    allow_remote_vpc_dns_resolution = true
  }

  accepter {
    allow_remote_vpc_dns_resolution = true
  }
}

# Add peering to route tables
resource "aws_route" "route_table_entry_handle_public" {
  route_table_id            = module.handle-server-vpc.public_route_table_ids[0]
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.handle_to_k8s_peering.id
}

resource "aws_route" "route_table_entry_handle_private" {
  route_table_id            = module.handle-server-vpc.private_route_table_ids[0]
  destination_cidr_block    = "10.0.0.0/16"
  vpc_peering_connection_id = aws_vpc_peering_connection.handle_to_k8s_peering.id
}
