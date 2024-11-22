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

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier              = "dissco-document-db-production"
  engine                          = "docdb"
  master_username                 = "disscomasteruser"
  master_password                 = ""
  backup_retention_period         = 7
  db_subnet_group_name            = data.terraform_remote_state.vpc-state.outputs.database_subnet_group
  vpc_security_group_ids          = [data.terraform_remote_state.vpc-state.outputs.database_security_group]
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.service.name
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "document-db-production-instance-1"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.t3.medium"
}

resource "aws_docdb_cluster_parameter_group" "service" {
  family = "docdb5.0"
  name   = "dissco-production-no-tls-parameter-group"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}