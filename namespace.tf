resource "kubernetes_namespace" "ondat" {
  metadata {
    name = local.namespace
    labels = {
      app = local.namespace
    }
  }
}
