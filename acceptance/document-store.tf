resource "aws_docdb_cluster" "docdb" {
  cluster_identifier      = "acc-document-db"
  engine                  = "docdb"
  master_username         = "disscomasteruser"
#  master_password         = ""
  backup_retention_period = 7
  db_subnet_group_name    = module.database-vpc.database_subnet_group
  vpc_security_group_ids  = [aws_security_group.database.id]
  skip_final_snapshot     = true
  db_cluster_parameter_group_name = aws_docdb_cluster_parameter_group.service.name
}

resource "aws_docdb_cluster_instance" "cluster_instances" {
  count              = 1
  identifier         = "acc-document-db-instance-1"
  cluster_identifier = aws_docdb_cluster.docdb.id
  instance_class     = "db.t3.medium"
}

resource "aws_docdb_cluster_parameter_group" "service" {
  family = "docdb4.0"
  name = "no-tls-parameter-group"

  parameter {
    name  = "tls"
    value = "disabled"
  }
}