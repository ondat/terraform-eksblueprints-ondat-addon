resource "kubernetes_secret" "etcd" {
  count = var.create_cluster ? 1 : 0
  metadata {
    name      = "storageos-etcd"
    namespace = local.namespace
    labels = {
      app = "storageos"
    }
  }


  data = {
    "etcd-client-ca.crt" = var.etcd_ca
    "etcd-client.crt"    = var.etcd_cert
    "etcd-client.key"    = var.etcd_key
  }

  type = "kubernetes.io/storageos"
}
