# TechWave Solutions — Proyecto DevOps

Ecosistema DevOps completo para la aplicación TechWave App: contenerización, orquestación, CI/CD automatizado, observabilidad y seguridad.

## Stack tecnológico

- **Aplicación**: Python 3.11 + Flask
- **Contenedores**: Docker (multi-stage build)
- **Orquestación**: Kubernetes (Kind, 3 nodos)
- **IaC**: Terraform + LocalStack (backend S3 remoto)
- **CI/CD**: GitHub Actions (tests, Trivy, build, push, actualización automática de tags)
- **Observabilidad**: Prometheus, Grafana, Loki, Tempo, OpenTelemetry Collector, Promtail, AlertManager
- **Seguridad**: Trivy, NetworkPolicies, usuario no-root, Kubernetes Secrets, GitHub Secrets
- **Empaquetado**: Helm chart para la aplicación con soporte Blue-Green Deployment

## Estructura del proyecto

```
Techwave-DevOps/
├── app/
│   ├── techwave_app.py          # Aplicación Flask
│   ├── test_app.py              # Tests con pytest
│   ├── requirements.txt
│   └── Dockerfile               # Multi-stage build
├── helm/
│   └── techwave-app/
│       ├── Chart.yaml
│       ├── values.yaml           # Valores comunes
│       ├── values-blue.yaml      # Versión blue
│       ├── values-green.yaml     # Versión green
│       └── templates/
│           ├── deployment.yaml
│           ├── service.yaml
│           ├── ingress.yaml
│           ├── secret.yaml
│           └── networkpolicy.yaml
├── kubernetes/
│   ├── monitoring/
│   │   ├── otel-values.yaml
│   │   ├── loki-values.yaml
│   │   ├── prometheus-rules.yaml
│   │   └── servicemonitor.yaml
│   └── networkpolicy-monitoring.yaml
├── terraform/
│   ├── main.tf
│   ├── variables.tf
│   ├── backend.tf
│   └── modules/kubernetes/
├── scripts/
│   ├── bootstrap.sh             # Instalación completa automatizada
│   ├── blue-green-switch.sh     # Cambio entre versiones
│   └── kind-config.yaml
└── .github/workflows/
    └── ci-cd.yaml               # Pipeline CI/CD
```

## Instalación rápida

### Requisitos previos

Ubuntu con Docker, Kind, Kubectl, Terraform, AWS CLI y Helm instalados.

### Despliegue completo

```bash
git clone https://github.com/JavRip/Techwave-DevOps
cd Techwave-DevOps
./scripts/bootstrap.sh
```

El script levanta LocalStack, crea el clúster Kind, aplica la infraestructura con Terraform, despliega la aplicación con Helm y configura el stack de monitoreo completo.

### Acceso

- **Aplicación**: `curl http://localhost/health -H "Host: techwave-app.local"`
- **Grafana**: `http://localhost:3000` (admin / techwave123)
- **Prometheus**: `http://localhost:9090`

## Pipeline CI/CD

Se ejecuta en cada push o pull request a main:

1. **Job 1 — Tests**: pytest + validación de sintaxis Python
2. **Job 2 — Build y Push** (solo push): build → Trivy scan → push a Docker Hub → actualización automática del tag en values.yaml
3. **Job 3 — Validación K8s**: helm template + kubeconform

## Blue-Green Deployment

```bash
./scripts/blue-green-switch.sh green   # Cambiar a versión green
./scripts/blue-green-switch.sh blue    # Volver a versión blue
```

## Observabilidad

| Componente | Función |
|---|---|
| Prometheus | Métricas (scrape cada 15s) |
| Grafana | Dashboards y visualización |
| Loki | Logs centralizados |
| Tempo | Trazas distribuidas |
| OTel Collector | Recolección y enrutamiento de trazas |
| Promtail | Recolección de logs |
| AlertManager | Gestión de alertas |

### Alertas configuradas

- Tasa de errores 503 superior al 10% durante 2 minutos
- Pods no disponibles durante 1 minuto
- Reinicio de pods más de 3 veces en 1 hora
- Uso de memoria superior al 80% durante 5 minutos

## Endpoints de la aplicación

| Endpoint | Descripción |
|---|---|
| `/` | Página principal |
| `/health` | Estado de salud (liveness/readiness) |
| `/metrics` | Métricas para Prometheus |
| `/metrics-custom` | Métricas en formato JSON |
| `/traces` | Trazas para OpenTelemetry |
| `/info` | Información del sistema |

## Autor

JavRip — Proyecto final del curso DevOps (Tokio School)