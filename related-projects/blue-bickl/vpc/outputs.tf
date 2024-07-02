output "blue_database_subnets" {
  value       = module.blue-bicikl-vpc.database_subnet_group
  description = "Private subnet of the BLUE EC2"
}

output "blue_public_subnets" {
  value       = module.blue-bicikl-vpc.public_subnets
  description = "Public subnets of the BLUE EC2"
}

output "blue_database_security_group" {
  value       = aws_security_group.blue-database-sg.id
  description = "Security group of the database"
}

output "blue_api_security_group" {
  value       = aws_security_group.blue-api-sg.id
  description = "Security group of the BLUE EC2"
}
