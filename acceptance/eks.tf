module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name                   = local.name
  cluster_version                = local.cluster_version
  cluster_endpoint_public_access = true

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  # EKS MANAGED NODE GROUPS
  eks_managed_node_groups = {
    managed_m5 = {
      node_group_name = local.node_group_name
      instance_types  = ["m5.large"]
      subnet_ids      = module.vpc.private_subnets
      capacity_type   = "ON_DEMAND"
      desired_size    = 3
      min_size        = 3
      max_size        = 5
    }
  }

  tags = local.tags
}