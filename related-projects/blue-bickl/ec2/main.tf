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

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "doi-terraform-state-backend"
    key    = "doi/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name = "doi_key"
  public_key = file("./blue-bicikl.pub")
}


resource "aws_instance" "blue-bicikl" {
  ami                         = "ami-0a244485e2e4ffd03"
  instance_type               = "t3.small"
  associate_public_ip_address = true

  key_name = aws_key_pair.key_pair.key_name

  subnet_id = data.terraform_remote_state.vpc-state.outputs.blue_subnets[0]
  vpc_security_group_ids = [data.terraform_remote_state.vpc-state.outputs.blue_security_group]
}