output "doi_database_subnets" {
  value       = module.doi-vpc.database_subnet_group
  description = "Private subnet of the DOI Server"
}

output "doi_server_subnets" {
  value       = module.doi-vpc.public_subnets
  description = "Public subnet of the DOI Server"
}

output "doi_peering_id" {
  value       = aws_vpc_peering_connection.doi_k8s_peering.id
  description = "Peering connection between DOI and K8s vpc"
}

output "doi_database_security_group" {
  value       = aws_security_group.doi-database-sg.id
  description = "Security group of the database"
}

output "doi_server_security_group" {
  value       = aws_security_group.doi-server-sg.id
  description = "Security group of the DOI server"
}
