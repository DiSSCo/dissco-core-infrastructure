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

resource "aws_eip" "static_ip" {
  domain   = "vpc"
  instance = aws_instance.doip_deployment.id
}

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "doip-terraform-state-backend"
    key    = "doip/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name = "doip_key"
  public_key = file("./doip_deployment.pub")
}

resource "aws_instance" "doip_deployment" {
  ami                         = "ami-0a244485e2e4ffd03"
  instance_type               = "t3.small"
  associate_public_ip_address = true
  key_name = aws_key_pair.key_pair.key_name

  subnet_id = data.terraform_remote_state.vpc-state.outputs.doip_subnets[0]
  vpc_security_group_ids = [data.terraform_remote_state.vpc-state.outputs.doip_security_group]
}
