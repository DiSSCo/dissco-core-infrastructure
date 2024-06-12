output "doi_database_subnets" {
  value       = module.doi-vpc.database_subnet_group
  description = "Private subnet of the DOI Server"
}

output "doi_server_subnets" {
  value       = module.doi-vpc.public_subnets
  description = "Private subnet of the DOI Server"
}

output "doi_database_security_group" {
  value       = aws_security_group.doi-database-sg.id
  description = "Security group of the database"
}

output "doi_server_security_group" {
  value       = aws_security_group.doi-server-sg.id
  description = "Security group of the DOI server"
}
