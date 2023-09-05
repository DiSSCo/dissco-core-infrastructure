provider "aws" {
  region = "eu-west-2"
  default_tags {
    tags = {
      Environment = "Acceptance"
      Owner       = "DiSSCo"
      Project     = "DiSSCo Core"
      Terraform   = "True"
    }
  }
}

data "terraform_remote_state" "vpc-state" {
  backend = "s3"

  config = {
    bucket = "dissco-terraform-state-backend"
    key    = "acceptance/vpc/terraform.tfstate"
    region = "eu-west-2"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "19.15.3"

  cluster_name                   = "dissco-k8s-acc"
  cluster_version                = 1.27
  cluster_endpoint_public_access = true

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id     = data.terraform_remote_state.vpc-state.outputs.k8s-vpc-id
  subnet_ids = data.terraform_remote_state.vpc-state.outputs.k8s-private-subnets

  # EKS MANAGED NODE GROUPS
  eks_managed_node_groups = {
    managed_m5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["m5.large"]
      subnet_ids      = data.terraform_remote_state.vpc-state.outputs.k8s-private-subnets
      capacity_type   = "ON_DEMAND"
      desired_size    = 3
      min_size        = 3
      max_size        = 5
    }
  }
}

module "eks_blueprints_kubernetes_addons" {
  source = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.32.1"
  depends_on = [
    module.eks
  ]
  eks_cluster_id = module.eks.cluster_name

  # EKS Addons
  enable_amazon_eks_aws_ebs_csi_driver = true

  #K8s Add-ons
  enable_argocd                                = true
  argocd_manage_add_ons                        = true
  enable_metrics_server                        = true
  enable_secrets_store_csi_driver              = true
  enable_secrets_store_csi_driver_provider_aws = true
  enable_keda                                  = true
  enable_strimzi_kafka_operator                = true

  argocd_applications = {
    app-of-apps = {
      repo_url           = "https://github.com/DiSSCo/dissco-core-deployment"
      target_revision    = "HEAD"
      path               = "shared-resources"
      add_on_application = true
    }
  }
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.20.0"
  create_role                   = true
  role_name                     = "secret-manager-acc"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.eks-secret-manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:default:secret-manager", "system:serviceaccount:default:dissco-orchestration-backend-sa"]
}

resource "aws_iam_policy" "eks-secret-manager" {
  name_prefix = "eks-secret-manager"
  description = "EKS secret-manager policy for cluster ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.secret-manager.json
}

data "aws_iam_policy_document" "secret-manager" {
  statement {
    sid    = "eksSecretManagerGetSecret"
    effect = "Allow"

    actions = [
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
    ]

    resources = ["*"]
  }
}