provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Production"
      Owner       = "DiSSCo"
      Project     = "DiSSCo PID"
      Terraform   = "True"
    }
  }
}

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "doi/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

# DOI Server
resource "aws_eip" "static_ip" {
  domain   = "vpc"
  instance = aws_instance.doi_server.id
}

resource "aws_key_pair" "key_pair" {
  key_name = "doi_key"
  public_key = file("./doi_server.pub")
}

resource "aws_instance" "doi_server" {
  ami                         = "ami-0a244485e2e4ffd03"
  instance_type               = "t3.small"
  associate_public_ip_address = true
  key_name = aws_key_pair.key_pair.key_name

  subnet_id = data.terraform_remote_state.vpc-state.outputs.pid_server_public_subnets[0]
  vpc_security_group_ids = [data.terraform_remote_state.vpc-state.outputs.pid_security_group]
  tags = {
    Name = "doi-server"
  }
}

# Handle Server
resource "aws_eip" "static_ip_handle" {
  domain   = "vpc"
  instance = aws_instance.handle_server.id
}

resource "aws_key_pair" "key_pair_handle" {
  key_name = "handle_key_production"
  public_key = file("./handle_server_production.pub")
}

resource "aws_instance" "handle_server" {
  ami                         = "ami-0a244485e2e4ffd03"
  instance_type               = "t3.small"
  associate_public_ip_address = true
  key_name = aws_key_pair.key_pair.key_name

  subnet_id = data.terraform_remote_state.vpc-state.outputs.pid_server_public_subnets[0]
  vpc_security_group_ids = [data.terraform_remote_state.vpc-state.outputs.pid_security_group]
  tags = {
    Name = "handle-server"
  }
}
