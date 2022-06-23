module "helm_addon" {
  source               = "github.com/aws-ia/terraform-aws-eks-blueprints//modules/kubernetes-addons/helm-addon?ref=v4.1.0"
  manage_via_gitops    = var.manage_via_gitops
  set_values           = local.set_values
  set_sensitive_values = local.set_sensitive_values
  helm_config          = local.helm_config
  irsa_config          = local.irsa_config
  addon_context        = var.addon_context
  depends_on           = [kubernetes_storage_class.etcd, kubernetes_namespace.ondat]
}
