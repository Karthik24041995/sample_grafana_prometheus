"""
Sample Flask application with Prometheus metrics endpoint
This simulates an Azure-hosted service that exposes metrics
"""
from flask import Flask, jsonify
from prometheus_client import Counter, Histogram, Gauge, generate_latest, REGISTRY
import random
import time

app = Flask(__name__)

# Define Prometheus metrics
REQUEST_COUNT = Counter(
    'http_requests_total', 
    'Total HTTP requests',
    ['method', 'endpoint', 'status']
)

REQUEST_DURATION = Histogram(
    'http_request_duration_seconds',
    'HTTP request duration in seconds',
    ['method', 'endpoint']
)

ACTIVE_USERS = Gauge(
    'active_users',
    'Number of active users'
)

ERROR_RATE = Counter(
    'application_errors_total',
    'Total application errors',
    ['error_type']
)

CPU_USAGE = Gauge(
    'cpu_usage_percent',
    'Simulated CPU usage percentage'
)

MEMORY_USAGE = Gauge(
    'memory_usage_bytes',
    'Simulated memory usage in bytes'
)

@app.route('/')
def home():
    REQUEST_COUNT.labels(method='GET', endpoint='/', status='200').inc()
    return jsonify({
        'message': 'Welcome to the monitored application!',
        'endpoints': ['/metrics', '/api/data', '/api/users', '/api/health']
    })

@app.route('/api/data')
def get_data():
    start_time = time.time()
    
    # Simulate some processing
    time.sleep(random.uniform(0.1, 0.5))
    
    # Randomly simulate errors
    if random.random() < 0.1:  # 10% error rate
        ERROR_RATE.labels(error_type='timeout').inc()
        REQUEST_COUNT.labels(method='GET', endpoint='/api/data', status='500').inc()
        return jsonify({'error': 'Timeout'}), 500
    
    REQUEST_COUNT.labels(method='GET', endpoint='/api/data', status='200').inc()
    duration = time.time() - start_time
    REQUEST_DURATION.labels(method='GET', endpoint='/api/data').observe(duration)
    
    return jsonify({
        'data': [1, 2, 3, 4, 5],
        'timestamp': time.time()
    })

@app.route('/api/users')
def get_users():
    start_time = time.time()
    
    # Simulate active users
    ACTIVE_USERS.set(random.randint(50, 200))
    
    REQUEST_COUNT.labels(method='GET', endpoint='/api/users', status='200').inc()
    duration = time.time() - start_time
    REQUEST_DURATION.labels(method='GET', endpoint='/api/users').observe(duration)
    
    return jsonify({
        'active_users': ACTIVE_USERS._value.get()
    })

@app.route('/api/health')
def health_check():
    # Simulate CPU and memory metrics
    CPU_USAGE.set(random.uniform(20, 80))
    MEMORY_USAGE.set(random.randint(500_000_000, 2_000_000_000))
    
    REQUEST_COUNT.labels(method='GET', endpoint='/api/health', status='200').inc()
    
    return jsonify({
        'status': 'healthy',
        'cpu_usage': CPU_USAGE._value.get(),
        'memory_usage': MEMORY_USAGE._value.get()
    })

@app.route('/metrics')
def metrics():
    """Prometheus metrics endpoint"""
    return generate_latest(REGISTRY), 200, {'Content-Type': 'text/plain; version=0.0.4; charset=utf-8'}

if __name__ == '__main__':
    print("Starting monitored application on port 5000...")
    print("Metrics available at: http://localhost:5000/metrics")
    app.run(host='0.0.0.0', port=5000)
