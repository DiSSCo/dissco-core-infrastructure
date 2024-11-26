output "eks-endpoint" {
  value       = module.eks.cluster_endpoint
  description = "Endpoint of the cluster"
}

output "cluster_addons" {
  value       = module.eks.cluster_addons
  description = "The cluster addons of EKS"
}