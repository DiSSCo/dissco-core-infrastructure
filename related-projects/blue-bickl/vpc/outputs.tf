output "blue_database_subnets" {
  value       = module.blue-bicikl-vpc.database_subnet_group
  description = "Private subnet of the DOI Server"
}

output "blue_server_subnets" {
  value       = module.blue-bicikl-vpc.public_subnets
  description = "Private subnet of the DOI Server"
}

output "blue_database_security_group" {
  value       = aws_security_group.blue-database-sg.id
  description = "Security group of the database"
}

output "blue_server_security_group" {
  value       = aws_security_group.blue-server-sg.id
  description = "Security group of the DOI server"
}
