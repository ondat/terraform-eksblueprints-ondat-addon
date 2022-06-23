resource "kubernetes_storage_class" "etcd" {
  count = length(var.etcd_endpoints) == 0 ? 1 : 0
  metadata {
    name = "etcd"
  }
  storage_provisioner = "ebs.csi.aws.com"
  reclaim_policy      = "Retain"
  volume_binding_mode = "WaitForFirstConsumer"
  parameters = {
    type = "gp3"
  }
}
