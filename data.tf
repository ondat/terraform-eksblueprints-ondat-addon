data "aws_region" "current" {}

data "aws_eks_cluster" "eks" {
  name = local.eks_cluster_id
}
