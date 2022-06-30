terraform {
  experiments = [module_variable_optional_attrs]
}
locals {
  name                 = "ondat"
  namespace            = "ondat"
  service_account_name = "storageos-operator"
  eks_cluster_id       = var.addon_context.eks_cluster_id

  ondat_etcd_endpoints            = length(var.etcd_endpoints) == 0 ? "storageos-etcd.storageos-etcd:2379" : join(",", var.etcd_endpoints)
  ondat_etcd_tls_secret           = length(kubernetes_secret.etcd) > 0 ? kubernetes_secret.etcd.0.metadata.0.name : "storageos-etcd-secret"
  ondat_etcd_tls_secret_namespace = length(kubernetes_secret.etcd) > 0 ? kubernetes_secret.etcd.0.metadata.0.namespace : "storageos"

  set_values = concat([
    {
      name  = "ondat-operator.serviceAccount.name"
      value = local.service_account_name
    },
    {
      name  = "ondat-operator.cluster.create"
      value = var.create_cluster
    },
    {
      name  = "ondat-operator.cluster.secretRefName"
      value = "storageos-api"
    },
    {
      name  = "ondat-operator.cluster.kvBackend.address"
      value = local.ondat_etcd_endpoints
    },
    {
      name  = "ondat-operator.cluster.kvBackend.tlsSecretName"
      value = local.ondat_etcd_tls_secret
    },
    {
      name  = "ondat-operator.cluster.kvBackend.tlsSecretNamespace"
      value = local.ondat_etcd_tls_secret_namespace
    },
    {
      name  = "etcd-cluster-operator.cluster.create"
      value = length(var.etcd_endpoints) == 0 ? true : false
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
    chart                      = "ondat"
    repository                 = "https://ondat.github.io/charts"
    version                    = "0.0.6"
    namespace                  = local.namespace
    timeout                    = "1500"
    create_namespace           = false
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

  argocd_gitops_config = {
    enable                             = true
    etcdClusterCreate                  = length(var.etcd_endpoints) == 0 ? true : false
    serviceAccountName                 = local.service_account_name
    clusterSecretRefName               = "storageos-api"
    clusterAdminUsername               = "storageos"
    clusterAdminPassword               = "storageos"
    clusterKvBackendAddress            = local.ondat_etcd_endpoints
    clusterKvBackendTLSSecretName      = length(kubernetes_secret.etcd) > 0 ? kubernetes_secret.etcd.0.metadata.0.name : "storageos-etcd-secret"
    clusterKvBackendTLSSecretNamespace = length(kubernetes_secret.etcd) > 0 ? kubernetes_secret.etcd.0.metadata.0.namespace : "storageos"
    clusterNodeSelectorTermKey         = "storageos-node"
    clusterNodeSelectorTermValue       = "1"
    etcdNodeSelectorTermKey            = "storageos-etcd"
    etcdNodeSelectorTermValue          = "1"
  }

  default_helm_values = [templatefile("${path.module}/values.yaml", {
    ondat_service_account_name   = local.service_account_name,
    namespace                    = local.namespace,
    ondat_nodeselectorterm_key   = "storageos-node"
    ondat_nodeselectorterm_value = "1"
    etcd_nodeselectorterm_key    = "storageos-etcd"
    etcd_nodeselectorterm_value  = "1"
    ondat_admin_username         = "storageos",
    ondat_admin_password         = "storageos",
    ondat_credential_secret_name = "storageos-api",
    etcd_address                 = local.ondat_etcd_endpoints,
    },
  )]
}
