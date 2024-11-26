output "doi_database_subnet_group" {
  value       = module.doi-vpc.database_subnet_group
  description = "Database subnet of the DOI Server"
}

output "doi_server_public_subnets" {
  value       = module.doi-vpc.public_subnets
  description = "Public subnet of the DOI Server"
}

output "doi_server_private_subnets" {
  value       = module.doi-vpc.private_subnets
  description = "Private subnets of the DOI Server"
}

output "doi_peering_id" {
  value       = aws_vpc_peering_connection.doi_k8s_peering.id
  description = "Peering connection between DOI and K8s vpc"
}

output "doi_security_group" {
  value       = aws_security_group.doi-vpc-sg.id
  description = "Security group of the DOI VPC"
}