#!/bin/bash
# setup-localstack.sh
# Script de inicialización del entorno LocalStack para el proyecto TechWave
# Crea los recursos AWS simulados necesarios antes de ejecutar Terraform

set -e  # Detener el script si cualquier comando falla

echo "🚀 Iniciando LocalStack..."
# Levantar LocalStack en segundo plano via Docker Compose
# Usar los servicios mínimos necesarios: S3 para el estado y ECR para las imágenes
docker run -d \
  --name localstack \
  -p 4566:4566 \
  -e SERVICES=s3,ecr \

echo "⏳ Esperando a que LocalStack esté listo..."
until aws --endpoint-url=http://localhost:4566 s3 ls &>/dev/null; do
  sleep 2
done

echo "🪣 Creando bucket S3 para el estado remoto de Terraform..."
aws --endpoint-url=http://localhost:4566 \
    --region eu-south-2 \
    s3 mb s3://techwave-terraform-state

# Habilitar el versionado del bucket: si algo corrompe el estado, se recupera la versión anterior.
aws --endpoint-url=http://localhost:4566 \
    --region eu-south-2 \
    s3api put-bucket-versioning \
    --bucket techwave-terraform-state \
    --versioning-configuration Status=Enabled
    
echo "✅ LocalStack está listo y el bucket S3 ha sido creado."