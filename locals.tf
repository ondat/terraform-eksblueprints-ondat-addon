terraform {
  experiments = [module_variable_optional_attrs]
}
locals {
  name                 = "ondat"
  namespace            = "storageos"
  service_account_name = "storageos-operator"
  eks_cluster_id       = var.addon_context.eks_cluster_id

  set_values = concat([
    {
      name  = "serviceAccount.name"
      value = local.service_account_name
    },
    {
      name  = "cluster.create"
      value = var.create_cluster
    },
    {
      name  = "cluster.secretRefName"
      value = "storageos-api"
    },
    {
      name  = "cluster.kvBackend.address"
      value = join(",", var.etcd_endpoints)
    },
    {
      name  = "cluster.kvBackend.tlsSecretName"
      value = var.create_cluster ? kubernetes_secret.etcd.0.metadata.0.name : ""
    },
    {
      name  = "cluster.kvBackend.tlsSecretNamespace"
      value = var.create_cluster ? kubernetes_secret.etcd.0.metadata.0.namespace : ""
    },
  ])

  set_sensitive_values = concat([
    {
      name  = "cluster.admin.username",
      value = var.admin_username
    },
    {
      name  = "cluster.admin.password",
      value = var.admin_password
    },
  ])

  default_helm_config = {
    name                       = local.name
    chart                      = "ondat-operator"
    repository                 = "https://ondat.github.io/charts"
    version                    = "0.5.6"
    namespace                  = local.namespace
    timeout                    = "1500"
    create_namespace           = true
    values                     = local.default_helm_values
    set                        = []
    set_sensitive              = null
    lint                       = true
    wait                       = true
    wait_for_jobs              = false
    description                = "Ondat Helm Chart for storage"
    verify                     = false
    keyring                    = ""
    repository_key_file        = ""
    repository_cert_file       = ""
    repository_ca_file         = ""
    repository_username        = ""
    repository_password        = ""
    disable_webhooks           = false
    reuse_values               = false
    reset_values               = false
    force_update               = false
    recreate_pods              = false
    cleanup_on_fail            = false
    max_history                = 0
    atomic                     = false
    skip_crds                  = false
    render_subchart_notes      = true
    disable_openapi_validation = false
    dependency_update          = false
    replace                    = false
    postrender                 = ""
  }

  helm_config = merge(
    local.default_helm_config,
    var.helm_config
  )

  irsa_config = {
    kubernetes_namespace              = local.namespace
    kubernetes_service_account        = local.service_account_name
    create_kubernetes_namespace       = false
    create_kubernetes_service_account = true
    iam_role_path                     = "/"
    tags                              = var.addon_context.tags
    eks_cluster_id                    = var.addon_context.eks_cluster_id
    irsa_iam_policies                 = var.irsa_policies
    irsa_iam_permissions_boundary     = var.irsa_permissions_boundary
  }


  default_helm_values = [templatefile("${path.module}/values.yaml", {
    service_account_name   = local.service_account_name,
    namespace              = local.namespace,
    admin_username         = "storageos",
    admin_password         = "storageos",
    credential_secret_name = "storageos-api",
    etcd_address           = "https://storageos-etcd.storageos.svc.cluster.local:2379",
    },
  )]

  argocd_gitops_config = {
    enable                             = true
    serviceAccountName                 = local.service_account_name
    clusterSecretRefName               = "storageos-api"
    clusterAdminUsername               = "storageos"
    clusterAdminPassword               = "storageos"
    clusterKvBackendAddress            = join(",", var.etcd_endpoints)
    clusterKvBackendTLSSecretName      = var.create_cluster ? kubernetes_secret.etcd.0.metadata.0.name : ""
    clusterKvBackendTLSSecretNamespace = var.create_cluster ? kubernetes_secret.etcd.0.metadata.0.namespace : ""
    clusterNodeSelectorTermKey         = "storageos-node"
    clusterNodeSelectorTermValue       = "1"
  }
}
