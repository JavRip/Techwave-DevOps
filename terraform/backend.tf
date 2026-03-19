# backend.tf
# Configura el almacenamiento remoto del estado de Terraform.
# En producción esto apuntaría a S3 real; aquí apuntamos a LocalStack
# mediante el endpoint override. La clave del bucket actúa como "ruta"
# del fichero de estado dentro del bucket.

terraform {
  backend "s3" {
    bucket = "techwave-terraform-state"
    key    = "techwave/terraform.tfstate"
    region = "eu-south-2"

    # Redirigir todas las llamadas de S3 a LocalStack en lugar de AWS
    endpoints = { 
        s3 = "http://localhost:4566"
    }
    access_key                  = "test"   # LocalStack acepta cualquier valor
    secret_key                  = "test"
    skip_credentials_validation = true     # No validar con AWS real
    skip_metadata_api_check     = true
    skip_requesting_account_id  = true
    use_path_style            = true     # Necesario para S3 con endpoint custom
  }
}