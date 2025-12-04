# Prometheus Query Language (PromQL) Examples for Learning

This document contains common PromQL queries to help you learn how to query metrics in Prometheus.

## Basic Queries

### 1. Simple Metric Selection
```promql
# Get current value of all http_requests_total metrics
http_requests_total

# Get active users
active_users

# Get CPU usage
cpu_usage_percent
```

### 2. Filtering by Labels
```promql
# Get requests only for the /api/data endpoint
http_requests_total{endpoint="/api/data"}

# Get requests with status 200
http_requests_total{status="200"}

# Multiple label filters
http_requests_total{endpoint="/api/data", status="200", method="GET"}

# Negative matching (not equal)
http_requests_total{status!="200"}

# Regular expression matching
http_requests_total{endpoint=~"/api/.*"}

# Negative regex matching
http_requests_total{endpoint!~"/api/.*"}
```

## Rate and Counter Functions

### 3. Rate of Change
```promql
# Request rate per second (averaged over 1 minute)
rate(http_requests_total[1m])

# Request rate over 5 minutes
rate(http_requests_total[5m])

# Rate for specific endpoint
rate(http_requests_total{endpoint="/api/data"}[1m])
```

### 4. Increase Function
```promql
# Total increase in requests over 5 minutes
increase(http_requests_total[5m])

# Increase in errors over 1 hour
increase(application_errors_total[1h])
```

### 5. irate (Instant Rate)
```promql
# Instant rate using last two data points
irate(http_requests_total[1m])
```

## Aggregation Operations

### 6. Sum
```promql
# Total requests per second across all endpoints
sum(rate(http_requests_total[1m]))

# Total requests per endpoint (group by endpoint)
sum by (endpoint) (rate(http_requests_total[1m]))

# Total requests per status code
sum by (status) (rate(http_requests_total[1m]))
```

### 7. Average
```promql
# Average CPU usage
avg(cpu_usage_percent)

# Average request duration by endpoint
avg by (endpoint) (http_request_duration_seconds)
```

### 8. Min/Max
```promql
# Maximum CPU usage
max(cpu_usage_percent)

# Minimum active users
min(active_users)

# Max request rate by endpoint
max by (endpoint) (rate(http_requests_total[1m]))
```

### 9. Count
```promql
# Count number of metrics
count(http_requests_total)

# Count unique endpoints
count by (endpoint) (http_requests_total)
```

## Histogram Queries

### 10. Histogram Quantiles
```promql
# 95th percentile request duration
histogram_quantile(0.95, rate(http_request_duration_seconds_bucket[5m]))

# 50th percentile (median)
histogram_quantile(0.50, rate(http_request_duration_seconds_bucket[5m]))

# 99th percentile by endpoint
histogram_quantile(0.99, sum by (endpoint, le) (rate(http_request_duration_seconds_bucket[5m])))
```

### 11. Average Duration from Histogram
```promql
# Average request duration
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

## Mathematical Operations

### 12. Arithmetic
```promql
# Calculate error rate percentage
(rate(http_requests_total{status="500"}[5m]) / rate(http_requests_total[5m])) * 100

# Memory usage in GB
memory_usage_bytes / 1024 / 1024 / 1024

# Requests per minute
rate(http_requests_total[1m]) * 60
```

### 13. Comparison Operators
```promql
# CPU usage above 50%
cpu_usage_percent > 50

# Active users between 100 and 150
active_users > 100 and active_users < 150
```

## Time Functions

### 14. Offset Modifier
```promql
# Current request rate
rate(http_requests_total[5m])

# Request rate 1 hour ago
rate(http_requests_total[5m] offset 1h)

# Compare current vs 1 day ago
rate(http_requests_total[5m]) - rate(http_requests_total[5m] offset 1d)
```

### 15. Prediction Functions
```promql
# Predict memory usage 4 hours from now based on last 1 hour trend
predict_linear(memory_usage_bytes[1h], 4*3600)
```

## Advanced Queries

### 16. Success Rate
```promql
# HTTP success rate (non-5xx responses)
sum(rate(http_requests_total{status!~"5.."}[5m])) / 
sum(rate(http_requests_total[5m])) * 100
```

### 17. Request Rate by Status
```promql
# Requests per second grouped by status
sum by (status) (rate(http_requests_total[1m]))
```

### 18. Top N Queries
```promql
# Top 5 endpoints by request rate
topk(5, sum by (endpoint) (rate(http_requests_total[5m])))

# Bottom 3 endpoints
bottomk(3, sum by (endpoint) (rate(http_requests_total[5m])))
```

### 19. Absent Function
```promql
# Alert if metric is missing
absent(up{job="sample-app"})

# Alert if no requests in last 5 minutes
absent(rate(http_requests_total[5m]))
```

### 20. Changes Function
```promql
# Number of times metric value changed in last hour
changes(active_users[1h])
```

## Useful Dashboard Queries

### 21. Request Rate Panel
```promql
# Total requests per second
sum(rate(http_requests_total[5m]))

# By endpoint
sum by (endpoint) (rate(http_requests_total[5m]))
```

### 22. Error Rate Panel
```promql
# Error rate percentage
(sum(rate(http_requests_total{status=~"5.."}[5m])) / 
 sum(rate(http_requests_total[5m]))) * 100
```

### 23. Latency Panel
```promql
# 95th percentile latency
histogram_quantile(0.95, sum by (le) (rate(http_request_duration_seconds_bucket[5m])))

# Average latency
rate(http_request_duration_seconds_sum[5m]) / rate(http_request_duration_seconds_count[5m])
```

### 24. Active Users Over Time
```promql
active_users
```

### 25. System Resources
```promql
# CPU usage
cpu_usage_percent

# Memory usage in MB
memory_usage_bytes / 1024 / 1024
```

## Time Range Syntax

- `[5m]` - Last 5 minutes
- `[1h]` - Last 1 hour
- `[1d]` - Last 1 day
- `[1w]` - Last 1 week

## Tips for Learning

1. **Start Simple**: Begin with basic metric selection, then add filters
2. **Use rate() for Counters**: Always use `rate()` or `increase()` with counter metrics
3. **Group Wisely**: Use `sum by (label)` to aggregate meaningfully
4. **Test in Prometheus UI**: Use http://localhost:9090 to test queries
5. **Visualize in Grafana**: Create dashboards at http://localhost:3000
6. **Check Labels**: Use `{__name__=~".+"}` to see all available metrics

## Common Patterns

### SLI/SLO Monitoring
```promql
# Availability (% of successful requests)
sum(rate(http_requests_total{status=~"2.."}[5m])) / 
sum(rate(http_requests_total[5m])) * 100

# Latency SLO (% of requests under 500ms)
(sum(rate(http_request_duration_seconds_bucket{le="0.5"}[5m])) / 
 sum(rate(http_request_duration_seconds_count[5m]))) * 100
```

### Resource Utilization
```promql
# CPU usage over time
avg_over_time(cpu_usage_percent[5m])

# Memory trend
deriv(memory_usage_bytes[1h])
```

### Error Budget
```promql
# Error budget burn rate
(sum(rate(http_requests_total{status=~"5.."}[1h])) / 
 sum(rate(http_requests_total[1h]))) / 0.01  # Assuming 1% error budget
```

---

## Practice Exercise

Try to answer these questions using PromQL:

1. What is the current request rate for the `/api/data` endpoint?
2. What percentage of requests are returning errors (5xx)?
3. What is the 99th percentile response time?
4. How many active users are there right now?
5. What is the trend in memory usage over the last hour?
6. Which endpoint has the highest request rate?
7. What was the request rate 1 hour ago compared to now?

Experiment with these queries in the Prometheus UI at http://localhost:9090!
