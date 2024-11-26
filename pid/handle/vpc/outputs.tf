output "handle_server_subnets" {
  value       = module.handle-server-vpc.public_subnets
  description = "Public subnet of the Handle Server"
}

output "handle_server_security_group" {
  value       = aws_security_group.handle-server-sg.id
  description = "Security group of the Handle server"
}

output "handle_peering_id" {
  value       = aws_vpc_peering_connection.handle_to_k8s_peering.id
  description = "Peering connection between handle server and its db"
}

output "handle_cidr_block" {
  value       = module.handle-server-vpc.vpc_cidr_block
  description = "Cidr block for Handle VPC"
}

output "handle_database_subnet_group" {
  value       = module.handle-server-vpc.database_subnet_group
  description = "Database subnet of the DOI Server"
}