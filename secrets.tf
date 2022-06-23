resource "kubernetes_namespace" "storageos" {
  count = length(var.etcd_endpoints) == 0 ? 0 : 1
  metadata {
    name = "storageos"
    labels = {
      app = local.namespace
    }
  }
}

resource "kubernetes_secret" "etcd" {
  count = length(var.etcd_endpoints) == 0 ? 0 : 1
  metadata {
    name      = "storageos-etcd"
    namespace = "storageos"
    labels = {
      app = local.namespace
    }
  }


  data = {
    "etcd-client-ca.crt" = var.etcd_ca
    "etcd-client.crt"    = var.etcd_cert
    "etcd-client.key"    = var.etcd_key
  }

  type = "kubernetes.io/storageos"
}
