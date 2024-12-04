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
    bucket = "dissco-terraform-state-backend"
    key    = "doi/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

resource "aws_docdb_cluster" "docdb" {
  cluster_identifier              = "dissco-document-db-doi"
  engine                          = "docdb"
  master_username                 = "doimasteruser"
  master_password                 = ""
  backup_retention_period         = 35
  db_subnet_group_name            = data.terraform_remote_state.vpc-state.outputs.doi_database_subnet_group
  vpc_security_group_ids          = [data.terraform_remote_state.vpc-state.outputs.doi_security_group]
  skip_final_snapshot             = true
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.service.name
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "document-db-doi-instance-1"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.r6g.xlarge"
}

resource "aws_docdb_cluster_parameter_group" "service" {
  family = "docdb5.0"
  name   = "dissco-doi-no-tls-parameter-group"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}