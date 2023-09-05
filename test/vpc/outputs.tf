output "database_subnet_group" {
  value = module.dissco-database-vpc.database_subnet_group
  description = "Subnet of the database"
}

output "database_security_group" {
  value = aws_security_group.dissco-database-sg.id
  description = "Subnet of the database"
}

output "k8s-private-subnets" {
  value = module.dissco-k8s-vpc.private_subnets
  description = "Private subnet of the k8s vpc"
}

output "k8s-vpc-id" {
  value = module.dissco-k8s-vpc.vpc_id
  description = "Vpc id of the k8s virtual network"
}