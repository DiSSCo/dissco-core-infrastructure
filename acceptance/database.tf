module "database-vpc" {
  source               = "terraform-aws-modules/vpc/aws"

  name                 = "dissco-acc-vpc"
  cidr                 = "10.51.0.0/16"
  azs                  = ["eu-west-2a", "eu-west-2b", "eu-west-2c"]
  private_subnets      = ["10.51.1.0/24", "10.51.2.0/24", "10.51.3.0/24"]
  public_subnets       = ["10.51.101.0/24", "10.51.102.0/24", "10.51.103.0/24"]
  database_subnets     = ["10.51.201.0/24", "10.51.202.0/24", "10.51.203.0/24"]
  create_igw           = true
  create_database_subnet_group           = true
  create_database_subnet_route_table     = true
  create_database_internet_gateway_route = true

  enable_dns_hostnames = true
  enable_dns_support   = true
  tags                 = local.tags
}

resource "aws_security_group" "database" {
  name        = local.database_name
  description = "Acceptance database security group"
  vpc_id      = module.database-vpc.vpc_id

  # ingress
  ingress {
      from_port   = 5432
      to_port     = 5432
      protocol    = "tcp"
      description = "PostgreSQL access from within VPC"
      cidr_blocks = [module.database-vpc.vpc_cidr_block, module.vpc.vpc_cidr_block]
    }
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    description = "PostgreSQL access for Sam Home"
    cidr_blocks = ["87.208.51.107/32"]
  }
  ingress {
    from_port   = 27017
    to_port     = 27017
    protocol    = "tcp"
    description = "MongoDB access from within VPC"
    cidr_blocks = [module.database-vpc.vpc_cidr_block, module.vpc.vpc_cidr_block]
  }

  tags = local.tags
}

resource "aws_vpc_peering_connection" "database_peering" {
  peer_vpc_id   = module.vpc.vpc_id
  vpc_id        = module.database-vpc.vpc_id
  auto_accept   = true
}

resource "aws_db_instance" "default" {
  allocated_storage           = 50
  max_allocated_storage       = 100
  db_name                     = "disscoaccdatabase"
  engine                      = "postgres"
  engine_version              = "15.2"
  instance_class              = "db.m6g.large"
  publicly_accessible         = true
  db_subnet_group_name        = module.database-vpc.database_subnet_group
  vpc_security_group_ids      = [aws_security_group.database.id]
  username                    = "disscomasteruser"
  manage_master_user_password = true
  skip_final_snapshot         = true
}