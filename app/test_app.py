from techwave_app import app

def test_info_devuelve_200():
    client = app.test_client()
    response = client.get('/info')
    assert response.status_code == 200

def test_info_contiene_techwave():
    client = app.test_client()
    response = client.get('/info')
    data = response.get_json()
    assert data['company'] == 'TechWave Solutions'

def test_health_devuelve_estado():
    client = app.test_client()
    response = client.get('/health')
    assert response.status_code in [200, 503]

def test_metrics_devuelve_estado():
    client = app.test_client()
    response = client.get('/metrics')
    assert 'http_requests_total' in response.data.decode('utf-8') and 'http_request_duration_seconds' in response.data.decode('utf-8') and 'app_uptime_seconds' in response.data.decode('utf-8')
    assert response.status_code == 200