output "doip_subnets" {
  value       = module.doip-vpc.public_subnets
  description = "Private subnet of DOIP Deployment"
}

output "doip_security_group" {
  value       = aws_security_group.doip-deployment-sg.id
  description = "Security group of the DOIP Deployment"
}
