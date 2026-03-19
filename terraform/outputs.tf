output "app_namespace" {
  description = "Namespace de Kubernetes donde está desplegada la aplicación"
  value       = module.kubernetes.namespace
}