variable "app_name" {
  description = "Nombre de la aplicación"
  type        = string
}

variable "environment" {
  description = "Entorno de despliegue"
  type        = string
}

variable "app_image" {
  description = "Imagen Docker a desplegar"
  type        = string
}