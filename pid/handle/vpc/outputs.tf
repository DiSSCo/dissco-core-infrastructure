output "handle_server_subnets" {
  value       = module.handle-server-vpc.public_subnets
  description = "Public subnet of the Handle Server"
}

output "handle_server_security_group" {
  value       = aws_security_group.handle-server-sg.id
  description = "Security group of the Handle server"
}

output "handle_peering_id" {
  value       = aws_vpc_peering_connection.handle_database_peering.id
  description = "Public subnet of the DOI Server"
}
