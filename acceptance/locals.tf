locals {

  name            = "acc-cluster"
  database_name   = "acc-database"
  region          = "eu-west-2"
  environment     = "acceptance"
  cluster_version = "1.27"

  vpc_cidr = "10.50.0.0/16"

  node_group_name = "managed-ondemand"

  tags = {
    Name  = local.name
    Environment = local.environment
  }
}