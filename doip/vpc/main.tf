provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "DOIP"
      Owner       = "BiCIKL"
      Project     = "BiCIKL WP 7.4"
      Terraform   = "True"
      Name        = "DOIP"
    }
  }
}

module "doip-vpc" {
  source = "terraform-aws-modules/vpc/aws"
  name                                   = "dopi-vpc"
  cidr                                   = "10.102.0.0/26"
  azs                                    = ["eu-west-2a"]
  private_subnets                        = ["10.102.0.0/28"]
  public_subnets                         = ["10.102.0.16/28"]
  create_igw                             = true

  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_security_group" "doip-deployment-sg" {
  name        = "doip-sg"
  description = "DOIP security group"
  vpc_id      = module.doip-vpc.vpc_id

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
    from_port   = 8888
    to_port     = 8888
    protocol    = "tcp"
    description = "Server Access to DOIP"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
