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

echo "[INFO] Verificando clúster de Kubernetes..."
if kubectl cluster-info &>/dev/null; then
  echo "[OK] Clúster kind ya está activo"
else
  echo "[INFO] Creando clúster kind..."
  kind create cluster --config scripts/kind-config.yaml
fi

echo "[INFO] Aplicando infraestructura con Terraform..."
cd terraform
terraform init -reconfigure -input=false

echo "[INFO] Sincronizando estado de Terraform..."
if ! terraform state list | grep -q "kubernetes_namespace"; then
  echo "[INFO] Importando recursos existentes..."
  terraform import module.kubernetes.kubernetes_namespace.app techwave 2>/dev/null || true
  terraform import module.kubernetes.kubernetes_config_map.app techwave/techwave-config 2>/dev/null || true
fi

terraform apply -auto-approve
cd ..

echo "[INFO] Aplicando manifiestos de Kubernetes..."
kubectl apply -f kubernetes/secret.yaml
kubectl apply -f kubernetes/deployment-blue.yaml
kubectl apply -f kubernetes/deployment-green.yaml
kubectl apply -f kubernetes/service-blue-green.yaml
kubectl apply -f kubernetes/ingress.yaml

echo "[INFO] Verificando stack de monitoreo..."
if ! helm list -n monitoring | grep -q monitoring; then
  echo "[INFO] Instalando kube-prometheus-stack..."
  helm install monitoring prometheus-community/kube-prometheus-stack \
    --namespace monitoring \
    --set grafana.adminPassword=techwave123 \
    --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
    --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false
fi

if ! helm list -n monitoring | grep -q loki; then
  echo "[INFO] Instalando Loki..."
  helm install loki grafana/loki-stack \
    --namespace monitoring \
    --set promtail.enabled=true \
    --set grafana.enabled=false
fi
echo "[OK] Stack de monitoreo listo"

echo "[INFO] Iniciando port-forwards de monitoreo..."
# Matar port-forwards anteriores si existen
pkill -f "port-forward" 2>/dev/null || true
sleep 1
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/loki 3100:3100 &
echo "[OK] Port-forwards activos: Grafana:3000, Prometheus:9090, Loki:3100"

echo "[OK] Entorno listo"
kubectl get all -n techwave