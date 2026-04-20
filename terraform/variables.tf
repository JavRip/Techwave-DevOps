# variables.tf
# Centralizar variables evita "magic strings" dispersos por el código
# y hace el proyecto reutilizable en distintos entornos sin tocar lógica

variable "aws_region" {
  description = "Región AWS (o LocalStack) donde se despliegan los recursos"
  type        = string
  default     = "eu-south-2"
}

variable "app_name" {
  description = "Nombre base de la aplicación, usado para nombrar todos los recursos"
  type        = string
  default     = "techwave"
}

variable "environment" {
  description = "Entorno de despliegue: development, staging o production"
  type        = string
  default     = "development"

  validation {
    condition     = contains(["development", "staging", "production"], var.environment)
    error_message = "El entorno debe ser development, staging o production."
  }
}

variable "app_image" {
  description = "Imagen Docker completa a desplegar (ej: tuusuario/techwave-app:latest)"
  type        = string
  default     = "JavRip/techwave-app:latest"
}