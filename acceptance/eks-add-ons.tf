module "eks_blueprints_kubernetes_addons" {
  source     = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons?ref=v4.32.1"
  depends_on = [
    module.eks
  ]
  eks_cluster_id = module.eks.cluster_name

  # EKS Addons
  enable_amazon_eks_aws_ebs_csi_driver = true

  #K8s Add-ons
  enable_argocd         = true
  argocd_manage_add_ons = true
  #  enable_cluster_autoscaler = true
  enable_metrics_server = true
  enable_secrets_store_csi_driver = true
  enable_secrets_store_csi_driver_provider_aws = true
  enable_keda               = true
  enable_strimzi_kafka_operator = true

  argocd_applications = {
    app-of-apps = {
      repo_url           = "https://github.com/DiSSCo/dissco-core-infrastructure"
      target_revision    = "HEAD"
      path               = "acceptance-argocd"
      add_on_application = true
    }
  }
}

module "iam_assumable_role_admin" {
  source                        = "terraform-aws-modules/iam/aws//modules/iam-assumable-role-with-oidc"
  version                       = "5.20.0"
  create_role                   = true
  role_name                     = "secret-manager"
  provider_url                  = replace(module.eks.cluster_oidc_issuer_url, "https://", "")
  role_policy_arns              = [aws_iam_policy.eks-secret-manager.arn]
  oidc_fully_qualified_subjects = ["system:serviceaccount:default:secret-manager"]
}

resource "aws_iam_policy" "eks-secret-manager" {
  name_prefix = "eks-secret-manager"
  description = "EKS secret-manager policy for cluster ${module.eks.cluster_name}"
  policy      = data.aws_iam_policy_document.cluster_autoscaler.json
}

data "aws_iam_policy_document" "cluster_autoscaler" {
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