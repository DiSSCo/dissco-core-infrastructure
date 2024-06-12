output "handle_server_subnets" {
  value       = module.handle-server-vpc.public_subnets
  description = "Private subnet of the Handle Server"
}

output "handle_server_security_group" {
  value       = aws_security_group.handle-server-sg.id
  description = "Security group of the Handle server"
}
