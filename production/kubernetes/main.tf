provider "aws" {
  region = "eu-north-1"
  default_tags {
    tags = {
      Environment = "Production"
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
    key    = "production/vpc/terraform.tfstate"
    region = "eu-north-1"
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "20.29.0"

  cluster_name                   = "dissco-k8s-production"
  cluster_version                = 1.31
  cluster_endpoint_public_access = true
  authentication_mode            = "API_AND_CONFIG_MAP"
  cloudwatch_log_group_retention_in_days = 0

  # EKS Cluster VPC and Subnet mandatory config
  vpc_id     = data.terraform_remote_state.vpc-state.outputs.k8s-vpc-id
  subnet_ids = data.terraform_remote_state.vpc-state.outputs.k8s-private-subnets

  node_security_group_tags = {
    "karpenter.sh/discovery" = "dissco-k8s-production"
  }

  # EKS MANAGED NODE GROUPS
  eks_managed_node_groups = {
    managed_m5 = {
      node_group_name = "managed-ondemand"
      instance_types  = ["m7g.large"]
      subnet_ids      = data.terraform_remote_state.vpc-state.outputs.k8s-private-subnets
      capacity_type   = "ON_DEMAND"
      desired_size    = 2
      min_size        = 2
      max_size        = 2
    }
  }
}

module "eks_blueprints_kubernetes_addons" {
  source     = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.32.1"
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
      path               = "production-helm-resources"
      add_on_application = true
    }
  }
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.48.0"
  create_role                   = true
  role_name                     = "secret-manager"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.eks-secret-manager.arn]
  oidc_fully_qualified_subjects = [
    "system:serviceaccount:default:secret-manager",
    "system:serviceaccount:default:dissco-orchestration-backend-sa",
    "system:serviceaccount:default:nu-search-sa",
    "system:serviceaccount:default:data-exporter-backend-service-account",
    "system:serviceaccount:translator-services:translator-secret-manager",
    "system:serviceaccount:machine-annotation-services:mas-secret-manager",
    "system:serviceaccount:data-export-job:data-export-job-service-account",
    "system:serviceaccount:otel:otel-service-account"
  ]
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

module "iam_assumable_role_karpenter_node" {
  source                = "terraform-aws-modules/iam/aws//modules/iam-assumable-role"
  version               = "5.48.0"
  create_role           = true
  role_requires_mfa     = false
  role_name             = "KarpenterNodeRole-dissco-k8s-production"
  trusted_role_services = [
    "ec2.amazonaws.com"
  ]
  custom_role_policy_arns = [
    "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
    "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
    "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
    "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  ]
}

module "iam_assumable_role_karpenter_controller" {
  source                         = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                        = "5.48.0"
  create_role                    = true
  role_name                      = "KarpenterControllerRole-dissco-k8s-production"
  provider_url                   = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns               = [aws_iam_policy.karpenter-controller-policy.arn]
  oidc_fully_qualified_subjects  = ["system:serviceaccount:karpenter:karpenter"]
  oidc_fully_qualified_audiences = ["sts.amazonaws.com"]
}

resource "aws_iam_policy" "karpenter-controller-policy" {
  name_prefix = "KarpenterControllerPolicy-dissco-k8s-production"
  description = "EKS secret-manager policy for cluster ${module.eks.cluster_name}"
  policy      = jsonencode({
    "Statement" : [
      {
        "Action" : [
          "ssm:GetParameter",
          "ec2:DescribeImages",
          "ec2:RunInstances",
          "ec2:DescribeSubnets",
          "ec2:DescribeSecurityGroups",
          "ec2:DescribeLaunchTemplates",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes",
          "ec2:DescribeInstanceTypeOfferings",
          "ec2:DescribeAvailabilityZones",
          "ec2:DeleteLaunchTemplate",
          "ec2:CreateTags",
          "ec2:CreateLaunchTemplate",
          "ec2:CreateFleet",
          "ec2:DescribeSpotPriceHistory",
          "pricing:GetProducts"
        ],
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "Karpenter"
      },
      {
        "Action" : "ec2:TerminateInstances",
        "Condition" : {
          "StringLike" : {
            "ec2:ResourceTag/karpenter.sh/nodepool" : "*"
          }
        },
        "Effect" : "Allow",
        "Resource" : "*",
        "Sid" : "ConditionalEC2Termination"
      },
      {
        "Effect" : "Allow",
        "Action" : "iam:PassRole",
        "Resource" : "arn:aws:iam::824841205322:role/KarpenterNodeRole-dissco-k8s-production",
        "Sid" : "PassNodeIAMRole"
      },
      {
        "Effect" : "Allow",
        "Action" : "eks:DescribeCluster",
        "Resource" : "arn:aws:eks:eu-north-1:824841205322:cluster/dissco-k8s-production",
        "Sid" : "EKSClusterEndpointLookup"
      },
      {
        "Sid" : "AllowScopedInstanceProfileCreationActions",
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : [
          "iam:CreateInstanceProfile"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:RequestTag/kubernetes.io/cluster/dissco-k8s-production" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : "eu-north-1"
          },
          "StringLike" : {
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedInstanceProfileTagActions",
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : [
          "iam:TagInstanceProfile"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/dissco-k8s-production" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "eu-north-1",
            "aws:RequestTag/kubernetes.io/cluster/dissco-k8s-production" : "owned",
            "aws:RequestTag/topology.kubernetes.io/region" : "eu-north-1"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*",
            "aws:RequestTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowScopedInstanceProfileActions",
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : [
          "iam:AddRoleToInstanceProfile",
          "iam:RemoveRoleFromInstanceProfile",
          "iam:DeleteInstanceProfile"
        ],
        "Condition" : {
          "StringEquals" : {
            "aws:ResourceTag/kubernetes.io/cluster/dissco-k8s-production" : "owned",
            "aws:ResourceTag/topology.kubernetes.io/region" : "eu-north-1"
          },
          "StringLike" : {
            "aws:ResourceTag/karpenter.k8s.aws/ec2nodeclass" : "*"
          }
        }
      },
      {
        "Sid" : "AllowInstanceProfileReadActions",
        "Effect" : "Allow",
        "Resource" : "*",
        "Action" : "iam:GetInstanceProfile"
      }
    ],
    "Version" : "2012-10-17"
  })
}