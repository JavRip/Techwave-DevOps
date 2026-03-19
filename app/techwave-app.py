from flask import Flask, jsonify, request
import datetime
import random
import os
import time
import threading
from prometheus_client import Counter, Histogram, generate_latest, CollectorRegistry
import psutil

cache_dir = "/app/cache"
if not os.path.exists(cache_dir):
    os.makedirs(cache_dir)

app = Flask(__name__)

REQUEST_COUNT = Counter('http_requests_total', 'Total HTTP requests', ['method', 'endpoint', 'status_code'])
REQUEST_DURATION = Histogram('http_request_duration_seconds', 'HTTP request duration', ['method', 'endpoint'])
APP_UPTIME = Counter('app_uptime_seconds', 'Application uptime in seconds')

start_time = time.time()
request_count = 0

def uptime_counter():
    while True:
        time.sleep(1)
        APP_UPTIME.inc()

uptime_thread = threading.Thread(target=uptime_counter, daemon=True)
uptime_thread.start()

@app.route('/metrics')
def metrics():
    """Endpoint de métricas para Prometheus"""
    registry = CollectorRegistry()
    registry.register(REQUEST_COUNT)
    registry.register(REQUEST_DURATION)
    registry.register(APP_UPTIME)
    return generate_latest(registry)

@app.route('/health')
def health():
    """Endpoint de salud para monitoreo y descubrimiento de servicios"""
    if random.random() < 0.05:
        status = "degraded"
        status_code = 503
    else:
        status = "healthy"
        status_code = 200
    
    REQUEST_COUNT.labels(method='GET', endpoint='/health', status_code=status_code).inc()
    
    response = jsonify({
        "status": status,
        "timestamp": datetime.datetime.now().isoformat(),
        "version": "1.0.0",
        "service": "devops-app"
    })
    
    response.headers['Content-Type'] = 'application/json'
    return response, status_code

@app.route('/metrics-custom')
def custom_metrics():
    """Endpoint de métricas personalizadas para dashboards"""
    global request_count
    request_count += 1
    
    memory_usage = psutil.virtual_memory().percent
    cpu_usage = psutil.cpu_percent()
    disk_usage = psutil.disk_usage('/').percent
    
    REQUEST_COUNT.labels(method='GET', endpoint='/metrics-custom', status_code=200).inc()
    
    return jsonify({
        "application_metrics": {
            "total_requests": request_count,
            "memory_percent": memory_usage,
            "cpu_percent": cpu_usage,
            "disk_percent": disk_usage,
            "uptime_seconds": int(time.time() - start_time)
        },
        "system_metrics": {
            "timestamp": datetime.datetime.now().isoformat(),
            "host": os.environ.get('HOSTNAME', 'unknown'),
            "environment": os.environ.get('ENVIRONMENT', 'development')
        }
    })

@app.route('/traces')
def traces():
    """Endpoint para demostrar trazas con OpenTelemetry"""
    start = time.time()
    
    time.sleep(random.uniform(0.1, 0.5))
    
    REQUEST_COUNT.labels(method='GET', endpoint='/traces', status_code=200).inc()
    
    duration = time.time() - start
    REQUEST_DURATION.labels(method='GET', endpoint='/traces').observe(duration)
    
    return jsonify({
        "message": "Trazas para OpenTelemetry",
        "operation_duration": duration,
        "timestamp": datetime.datetime.now().isoformat()
    })

@app.route('/info')
def info():
    """Información del sistema para observabilidad"""
    REQUEST_COUNT.labels(method='GET', endpoint='/info', status_code=200).inc()
    
    return jsonify({
        "company": "TechWave Solutions",
        "app_name": "TechWave App",
        "environment": os.environ.get('ENVIRONMENT', 'development'),
        "pod_name": os.environ.get('HOSTNAME', 'unknown'),
        "namespace": os.environ.get('NAMESPACE', 'default'),
        "version": "1.0.0",
        "deployment_timestamp": datetime.datetime.now().isoformat(),
        "architecture": {
            "monitoring": {
                "prometheus": "/metrics",
                "custom_metrics": "/metrics-custom",
                "health": "/health",
                "traces": "/traces"
            }
        }
    })

@app.route('/')
def home():
    """Página principal con información básica"""
    REQUEST_COUNT.labels(method='GET', endpoint='/', status_code=200).inc()
    
    return """
    <h1>¡Bienvenido a TechWave Solutions!</h1>
    <p>Esta es una aplicación creada para el proyecto final de DevOps.</p>
    <p>Desplegada mediante pipeline CI/CD en Kubernetes.</p>
    <br>
    <h3>Endpoints de Monitoreo:</h3>
    <ul>
        <li><a href="/health">Ver estado de salud</a></li>
        <li><a href="/metrics">Métricas de Prometheus</a></li>
        <li><a href="/metrics-custom">Métricas personalizadas</a></li>
        <li><a href="/traces">Trazas para OpenTelemetry</a></li>
        <li><a href="/info">Información del sistema</a></li>
    </ul>
    <br>
    <h3>Integraciones:</h3>
    <ul>
        <li>Prometheus para métricas</li>
        <li>OpenTelemetry para trazas y métricas</li>
        <li>Grafana para dashboards</li>
        <li>Loki para logs</li>
    </ul>
    """

@app.before_request
def before_request():
    request.start_time = time.time()

@app.after_request
def after_request(response):
    if hasattr(request, 'start_time'):
        duration = time.time() - request.start_time
        REQUEST_DURATION.labels(
            method=request.method,
            endpoint=request.endpoint or 'unknown'
        ).observe(duration)
    return response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=False)