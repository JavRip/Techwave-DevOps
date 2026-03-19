output "namespace" {
  description = "Namespace de Kubernetes creado para la aplicación"
  value       = kubernetes_namespace.app.metadata[0].name
}