# TechWave DevOps — Proyecto Final

Implementación de un ecosistema DevOps completo para la aplicación web TechWave App: contenerización, orquestación con Kubernetes, pipeline CI/CD automatizado, despliegue Blue-Green y stack de observabilidad con métricas, logs, trazas y alertas.

## Stack tecnológico

| Categoría | Herramienta |
|---|---|
| Aplicación | Python 3.11 + Flask |
| Contenerización | Docker (imagen `python:3.11-slim`) |
| Registro de imágenes | Docker Hub (`javrip/techwave-app`) |
| Orquestación | Kubernetes con kind (3 nodos) |
| IaC | Terraform (backend S3 en LocalStack) |
| CI/CD | GitHub Actions (3 jobs) |
| Ingress | nginx-ingress-controller |
| Despliegue | Blue-Green Deployment |
| Monitoreo | kube-prometheus-stack, Loki 3.6.7, Promtail, OTel Collector |
| Visualización | Grafana |

## Estructura del repositorio

```
Techwave-DevOps/
├── app/
│   ├── techwave-app.py
│   ├── Dockerfile
│   ├── docker-compose.yml
│   └── requirements.txt
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── backend.tf
│   └── modules/kubernetes/
├── kubernetes/
│   ├── deployment-blue.yaml
│   ├── deployment-green.yaml
│   ├── service-blue-green.yaml
│   ├── ingress.yaml
│   ├── secret.yaml
│   └── monitoring/
│       ├── servicemonitor.yaml
│       ├── prometheus-rules.yaml
│       └── otel-values.yaml
├── .github/workflows/
│   └── ci-cd.yaml
├── scripts/
│   ├── kind-config.yaml
│   ├── bootstrap.sh
│   └── blue-green-switch.sh
└── .gitignore
```

## Requisitos previos

- Ubuntu (máquina física o virtual)
- Docker
- kind
- kubectl
- Terraform
- AWS CLI
- Helm

## Instalación rápida

El script `bootstrap.sh` automatiza toda la instalación y configuración:

```bash
git clone https://github.com/JavRip/Techwave-DevOps
cd Techwave-DevOps
./scripts/bootstrap.sh
```

## Instalación manual

### 1. Clonar el repositorio

```bash
git clone https://github.com/JavRip/Techwave-DevOps
cd Techwave-DevOps
```

### 2. Levantar LocalStack y crear bucket S3

```bash
docker run -d \
  --name localstack \
  --restart unless-stopped \
  -p 4566:4566 \
  -e SERVICES=s3 \
  localstack/localstack:latest

aws --endpoint-url=http://localhost:4566 --region eu-south-2 \
  s3 mb s3://techwave-terraform-state

aws --endpoint-url=http://localhost:4566 --region eu-south-2 \
  s3api put-bucket-versioning \
  --bucket techwave-terraform-state \
  --versioning-configuration Status=Enabled
```

### 3. Crear clúster kind

```bash
kind create cluster --config scripts/kind-config.yaml
```

### 4. Aplicar infraestructura con Terraform

```bash
cd terraform
terraform init -reconfigure -input=false
terraform apply -auto-approve
cd ..
```

### 5. Aplicar manifiestos de Kubernetes

```bash
kubectl apply -f kubernetes/secret.yaml
kubectl apply -f kubernetes/deployment-blue.yaml
kubectl apply -f kubernetes/deployment-green.yaml
kubectl apply -f kubernetes/service-blue-green.yaml
kubectl apply -f kubernetes/ingress.yaml
```

### 6. Instalar stack de monitoreo

```bash
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo add grafana https://grafana.github.io/helm-charts
helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts
helm repo update

helm install monitoring prometheus-community/kube-prometheus-stack \
  --namespace monitoring \
  --create-namespace \
  --set grafana.adminPassword=techwave123 \
  --set prometheus.prometheusSpec.podMonitorSelectorNilUsesHelmValues=false \
  --set prometheus.prometheusSpec.serviceMonitorSelectorNilUsesHelmValues=false

cd kubernetes/monitoring
kubectl apply -f prometheus-rules.yaml
kubectl apply -f servicemonitor.yaml
helm install otel open-telemetry/opentelemetry-collector -f otel-values.yaml \
  --namespace monitoring
cd ../..

helm install loki grafana/loki \
  --namespace monitoring \
  --set grafana.enabled=false

helm install promtail grafana/promtail \
  --namespace monitoring \
  --set "config.clients[0].url=http://loki.monitoring.svc.cluster.local:3100/loki/api/v1/push"
```

### 7. Port-forwarding

```bash
kubectl port-forward -n monitoring svc/monitoring-grafana 3000:80 &
kubectl port-forward -n monitoring svc/monitoring-kube-prometheus-prometheus 9090:9090 &
kubectl port-forward -n monitoring svc/loki 3100:3100 &
```

### 8. Acceso

- **Aplicación:** http://techwave.local
- **Grafana:** http://localhost:3000 (admin / techwave123)
- **Prometheus:** http://localhost:9090

## Blue-Green Deployment

Cambiar la versión activa:

```bash
./scripts/blue-green-switch.sh green   # Cambiar a green
./scripts/blue-green-switch.sh blue    # Volver a blue
```

## Endpoints de la aplicación

| Endpoint | Descripción |
|---|---|
| `/health` | Estado de la app (liveness/readiness probes) |
| `/metrics` | Métricas en formato Prometheus |
| `/metrics-custom` | Métricas en formato JSON |
| `/traces` | Trazas para OpenTelemetry |

## Alertas configuradas

| Alerta | Condición | Severidad |
|---|---|---|
| HighErrorRate | >10% errores HTTP en 2 min | Warning |
| NoPodsAvailable | 0 pods disponibles | Critical |
| PodRestartingTooOften | >3 reinicios en 1 hora | Warning |
| HighMemoryUsage | >80% memoria durante 5 min | Warning |

## Autor

JavRip
