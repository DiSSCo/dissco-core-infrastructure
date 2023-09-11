data "aws_eks_cluster_auth" "this" {
  name = module.eks.cluster_name
}
