provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "BiCIKL"
      Owner       = "DiSSCo"
      Project     = "Blue-BICIKL"
      Terraform   = "True"
      Name        = "Blue-BICIKL"
    }
  }
}

module "blue-bicikl-vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name                                   = "blue-vpc"
  cidr                                   = "10.200.0.0/16"
  azs                                    = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets                        = ["10.200.1.0/24", "10.200.2.0/24", "10.200.3.0/24"]
  public_subnets                         = ["10.200.101.0/24", "10.200.102.0/24", "10.200.103.0/24"]
  database_subnets                       = ["10.200.201.0/24", "10.200.202.0/24", "10.200.203.0/24"]
  create_igw                             = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "blue-database-sg" {
  name        = "blue-database-sg"
  description = "BLUE database security group"
  vpc_id      = module.blue-bicikl-vpc.vpc_id

  # ingress
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access from within VPC"
  }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Sou"
    cidr_blocks = ["203.109.214.6/32"]
  }

  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access from within VPC"
    cidr_blocks = [module.blue-bicikl-vpc.vpc_cidr_block]
  }
}

resource "aws_security_group" "blue-api-sg" {
  name        = "blue-api-sg"
  description = "BLUE API security group"
  vpc_id      = module.blue-bicikl-vpc.vpc_id

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
    description = "SSH Access for Sou"
    cidr_blocks = ["203.109.214.6/32"]
  }
  ingress {
    from_port   = 8000
    to_port     = 8000
    protocol    = "tcp"
    description = "HTTP Access to BLUE API"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    description = "HTTP Access to blue API"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    description = "HTTPS Access to blue API"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
