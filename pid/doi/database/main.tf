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

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "doi-terraform-state-backend"
    key    = "doi/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_db_instance" "default" {
  allocated_storage      = 50
  max_allocated_storage  = 100
  db_name                = "doistorage"
  engine                 = "postgres"
  engine_version         = "15.2"
  instance_class         = "db.m6g.large"
  publicly_accessible    = true
  db_subnet_group_name   = data.terraform_remote_state.vpc-state.outputs.doi_database_subnets
  vpc_security_group_ids = [
    data.terraform_remote_state.vpc-state.outputs.doi_database_security_group
  ]
  username                    = "doimasteruser"
  manage_master_user_password = true
  skip_final_snapshot         = true
  backup_retention_period     = 14
  maintenance_window          = "Mon:00:00-Mon:03:00"
  backup_window               = "03:00-06:00"
  lifecycle {
    prevent_destroy = true
  }
}

