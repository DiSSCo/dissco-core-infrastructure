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

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "handle/vpc/terraform.tfstate"
    region = "eu-north-1"
  }
}

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier              = "dissco-document-db-handle"
  engine                          = "docdb"
  master_username                 = "disscomasteruser"
  master_password                 = ""
  backup_retention_period         = 14
  db_subnet_group_name            = data.terraform_remote_state.vpc-state.outputs.handle_database_subnet_group
  vpc_security_group_ids          = [data.terraform_remote_state.vpc-state.outputs.handle_security_group]
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.service.name
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "document-db-handle-instance-1"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.r7g.xlarge"
}

resource "aws_docdb_cluster_parameter_group" "service" {
  family = "docdb5.0"
  name   = "dissco-handle-no-tls-parameter-group"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}