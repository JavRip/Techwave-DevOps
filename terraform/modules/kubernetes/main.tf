resource "kubernetes_namespace" "app" {
  metadata {
    name = var.app_name
    labels = {
      environment = var.environment
      managed-by  = "terraform"
    }
  }
}

resource "kubernetes_config_map" "app" {
  metadata {
    name      = "${var.app_name}-config"
    namespace = kubernetes_namespace.app.metadata[0].name
  }

  data = {
    ENVIRONMENT = var.environment
    NAMESPACE   = var.app_name
  }
}