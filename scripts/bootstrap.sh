#!/bin/bash
# bootstrap.sh
# Reconstruye el entorno completo de desarrollo desde cero.
# Ejecutar tras reinicios de la VM o pérdida de contenedores.

set -e
cd "$(dirname "$0")/.."

echo "[INFO] Verificando herramientas necesarias..."
for tool in docker kind kubectl terraform aws; do
  if ! command -v $tool &>/dev/null; then
    echo "[ERROR] $tool no está instalado o no está en el PATH"
    exit 1
  fi
done
echo "[OK] Todas las herramientas disponibles"

echo "[INFO] Levantando LocalStack..."
if docker ps | grep -q localstack; then
  echo "[OK] LocalStack ya está corriendo"
elif docker ps -a | grep -q localstack; then
  docker start localstack
  echo "[OK] LocalStack reiniciado"
else
  docker run -d \
    --name localstack \
    --restart unless-stopped \
    -p 4566:4566 \
    -e SERVICES=s3 \
    -e PERSISTENCE=1 \
    localstack/localstack:latest
fi

echo "[INFO] Esperando a que LocalStack esté listo..."
until aws --endpoint-url=http://localhost:4566 s3 ls &>/dev/null; do
  sleep 2
done
echo "[OK] LocalStack listo"

echo "[INFO] Verificando bucket S3..."
if ! aws --endpoint-url=http://localhost:4566 s3 ls s3://techwave-terraform-state &>/dev/null; then
  echo "[INFO] Creando bucket S3..."
  aws --endpoint-url=http://localhost:4566 \
      --region eu-south-2 \
      s3 mb s3://techwave-terraform-state
  aws --endpoint-url=http://localhost:4566 \
      --region eu-south-2 \
      s3api put-bucket-versioning \
      --bucket techwave-terraform-state \
      --versioning-configuration Status=Enabled
fi
echo "[OK] Bucket S3 listo"

elif docker ps -a | grep -q localstack; then
  docker start localstack
  echo "[OK] LocalStack reiniciado"
else
  docker run -d \
    --name localstack \
    --restart unless-stopped \
    -p 4566:4566 \
    -e SERVICES=s3 \
    -e DEFAULT_REGION=eu-south-2 \
    -e DATA_DIR=/tmp/localstack/data \
    localstack/localstack:latest
  echo "[INFO] Esperando a que LocalStack esté listo..."
  until aws --endpoint-url=http://localhost:4566 s3 ls &>/dev/null; do
    sleep 2
  done
  aws --endpoint-url=http://localhost:4566 \
      --region eu-south-2 \
      s3 mb s3://techwave-terraform-state 2>/dev/null || true
  aws --endpoint-url=http://localhost:4566 \
      --region eu-south-2 \
      s3api put-bucket-versioning \
      --bucket techwave-terraform-state \
      --versioning-configuration Status=Enabled
fi

echo "[INFO] Verificando clúster de Kubernetes..."
if kubectl cluster-info &>/dev/null; then
  echo "[OK] Clúster kind ya está activo"
else
  echo "[INFO] Creando clúster kind..."
  kind create cluster --config scripts/kind-config.yaml
fi

echo "[INFO] Aplicando infraestructura con Terraform..."
cd terraform
terraform init -reconfigure
echo "[INFO] Sincronizando estado de Terraform..."
terraform init -reconfigure -input=false

# Importar recursos si el estado está vacío pero los recursos existen
if ! terraform state list | grep -q "kubernetes_namespace"; then
  echo "[INFO] Importando recursos existentes..."
  terraform import module.kubernetes.kubernetes_namespace.app techwave 2>/dev/null || true
  terraform import module.kubernetes.kubernetes_config_map.app techwave/techwave-config 2>/dev/null || true
fi
cd ..
terraform apply -auto-approve

echo "[INFO] Aplicando manifiestos de Kubernetes..."
kubectl apply -f kubernetes/secret.yaml
kubectl apply -f kubernetes/deployment.yaml
kubectl apply -f kubernetes/service.yaml

echo "[OK] Entorno listo"
kubectl get all -n techwave
