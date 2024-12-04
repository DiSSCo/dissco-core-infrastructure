provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Production"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Core"
      Terraform   = "True"
    }
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

resource "aws_db_instance" "default" {
  allocated_storage           = 50
  max_allocated_storage       = 800
  db_name                     = "disscodatabaseproduction"
  engine                      = "postgres"
  engine_version              = "17.2"
  allow_major_version_upgrade = true
  instance_class              = "db.m7i.large"
  publicly_accessible         = true
  db_subnet_group_name        = data.terraform_remote_state.vpc-state.outputs.database_subnet_group
  vpc_security_group_ids      = [data.terraform_remote_state.vpc-state.outputs.database_security_group]
  username                    = "disscomasteruser"
  manage_master_user_password = true
  skip_final_snapshot         = true
  backup_retention_period     = 14
  maintenance_window          = "Mon:00:00-Mon:03:00"
  backup_window               = "03:00-06:00"
}