# main.tf
# Punto de entrada de Terraform. Declara los providers necesarios
# y llama a los módulos que construyen la infraestructura.

terraform {
  required_providers {
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }
  }
  required_version = ">= 1.5.0"
}

# Provider Kubernetes apuntando al clúster kind que se creará.
# El kubeconfig lo genera kind automáticamente al crear el clúster
provider "kubernetes" {
  config_path    = "~/.kube/config"
  config_context = "kind-techwave"  # nombre del contexto que kind asignará
}

# Llamada al módulo que gestiona los recursos del clúster Kubernetes
module "kubernetes" {
  source       = "./modules/kubernetes"
  app_name     = var.app_name
  app_image    = var.app_image
  environment  = var.environment
}