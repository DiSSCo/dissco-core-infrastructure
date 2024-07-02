provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Handle"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Handle"
      Terraform   = "True"
      Name        = "handle-server"
    }
  }
}

resource "aws_eip" "static_ip" {
  domain   = "vpc"
  instance = aws_instance.handle_server.id
}

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "handle/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_key_pair" "key_pair" {
  key_name = "handle_key"
  public_key = file("./handle_server.pub")
}

resource "aws_instance" "handle_server" {
  ami                         = "ami-0a244485e2e4ffd03"
  instance_type               = "t3.small"
  associate_public_ip_address = true
  key_name = aws_key_pair.key_pair.key_name

  subnet_id = data.terraform_remote_state.vpc-state.outputs.handle_server_subnets[0]
  vpc_security_group_ids = [data.terraform_remote_state.vpc-state.outputs.handle_server_security_group]
}
