# Azure Kubernetes Service (AKS) Deployment Guide

## Prerequisites

- Azure subscription
- Azure CLI installed
- kubectl installed (or will be installed automatically)
- Docker (for local testing - optional)

## Architecture

This deployment creates:
- **Azure Kubernetes Service (AKS)** cluster with 2 nodes
- **Azure Container Registry (ACR)** for storing Docker images
- **Log Analytics Workspace** for monitoring
- **Kubernetes workloads**:
  - Sample Flask application (2 replicas)
  - Prometheus server (with Kubernetes pod discovery)
  - Grafana dashboard (with Prometheus datasource pre-configured)

## Deployment Steps

### 1. Deploy to Azure

Run the deployment script:

```powershell
.\deploy-aks.ps1
```

Or with custom parameters:

```powershell
.\deploy-aks.ps1 -ResourceGroupName "my-rg" -Location "eastus" -ClusterName "my-aks"
```

The deployment process will:
1. Create Azure resource group
2. Deploy AKS cluster (~10-15 minutes)
3. Deploy Azure Container Registry
4. Build and push Docker images
5. Configure kubectl
6. Deploy Kubernetes manifests
7. Wait for LoadBalancer external IPs
8. Display access URLs

### 2. Access Applications

After deployment completes, you'll see URLs for:

- **Sample App**: `http://<external-ip>` - Flask application exposing metrics
- **Prometheus**: `http://<external-ip>:9090` - Metrics collection and queries
- **Grafana**: `http://<external-ip>` - Visualization dashboard
  - Username: `admin`
  - Password: `TestPassword123!`

### 3. Configure Grafana

1. Open Grafana URL in browser
2. Login with admin credentials
3. Prometheus datasource is pre-configured
4. Create a new dashboard or explore metrics

## Kubernetes Commands

### View Cluster Resources

```powershell
# Get all pods in monitoring namespace
kubectl get pods -n monitoring

# Get services and external IPs
kubectl get services -n monitoring

# View pod logs
kubectl logs -n monitoring <pod-name>

# Describe a pod
kubectl describe pod -n monitoring <pod-name>

# Get cluster nodes
kubectl get nodes
```

### Access Kubernetes Dashboard

```powershell
az aks browse --resource-group rg-prometheus-aks --name promlearn-aks
```

### Port Forwarding (Alternative Access)

If LoadBalancers are not ready:

```powershell
# Forward Grafana port
kubectl port-forward -n monitoring svc/grafana 3000:80

# Forward Prometheus port
kubectl port-forward -n monitoring svc/prometheus 9090:9090

# Forward Sample App port
kubectl port-forward -n monitoring svc/sample-app 5000:80
```

Then access:
- Grafana: http://localhost:3000
- Prometheus: http://localhost:9090
- Sample App: http://localhost:5000

## Prometheus Configuration

Prometheus is configured with Kubernetes pod discovery, automatically scraping pods with these annotations:

```yaml
annotations:
  prometheus.io/scrape: "true"
  prometheus.io/port: "5000"
  prometheus.io/path: "/metrics"
```

The sample app pods have these annotations, so Prometheus will discover and scrape them automatically.

## Sample PromQL Queries

See `PROMETHEUS_QUERIES.md` for comprehensive examples. Quick starts:

```promql
# Total HTTP requests by status code
sum by (status) (http_requests_total)

# Request rate per second
rate(http_requests_total[5m])

# CPU usage
cpu_usage_percent

# Memory usage in MB
memory_usage_bytes / 1024 / 1024

# Active users
active_users
```

## Generate Traffic

To generate sample metrics:

```powershell
# Run traffic generator (requires sample app external IP)
.\generate-traffic.ps1 -BaseUrl "http://<sample-app-ip>"
```

Or manually:

```powershell
# Get sample app IP
$sampleAppIP = kubectl get service -n monitoring sample-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'

# Generate requests
for ($i = 1; $i -le 100; $i++) {
    Invoke-WebRequest -Uri "http://$sampleAppIP/api/data" -UseBasicParsing
    Invoke-WebRequest -Uri "http://$sampleAppIP/api/users" -UseBasicParsing
    Invoke-WebRequest -Uri "http://$sampleAppIP/api/health" -UseBasicParsing
    Start-Sleep -Milliseconds 500
}
```

## Scaling

### Scale Sample App

```powershell
# Scale to 3 replicas
kubectl scale deployment -n monitoring sample-app --replicas=3

# Verify scaling
kubectl get pods -n monitoring -l app=sample-app
```

### Scale AKS Cluster

```powershell
az aks scale --resource-group rg-prometheus-aks --name promlearn-aks --node-count 3
```

## Troubleshooting

### Pods Not Starting

```powershell
# Check pod status
kubectl get pods -n monitoring

# View pod events
kubectl describe pod -n monitoring <pod-name>

# Check logs
kubectl logs -n monitoring <pod-name>
```

### LoadBalancer Pending

```powershell
# Check service status
kubectl get services -n monitoring

# If stuck in Pending, check AKS networking
az aks show --resource-group rg-prometheus-aks --name promlearn-aks --query "networkProfile"
```

### ACR Pull Errors

```powershell
# Verify AKS can access ACR
az aks check-acr --resource-group rg-prometheus-aks --name promlearn-aks --acr <acr-name>

# Attach ACR to AKS
az aks update --resource-group rg-prometheus-aks --name promlearn-aks --attach-acr <acr-name>
```

### Prometheus Not Scraping

```powershell
# Check Prometheus targets (http://<prometheus-ip>:9090/targets)
# Verify pod annotations
kubectl get pods -n monitoring -o yaml | grep -A 3 "annotations:"

# Check Prometheus logs
kubectl logs -n monitoring -l app=prometheus
```

## Cleanup

To remove all resources:

```powershell
.\cleanup-aks.ps1
```

Or with no confirmation prompt:

```powershell
.\cleanup-aks.ps1 -Force
```

This will delete:
- AKS cluster
- Azure Container Registry
- Log Analytics workspace
- All associated resources

## Cost Estimation

Approximate monthly costs (East US region):
- AKS cluster (2 x Standard_B2s): ~$60
- Azure Container Registry (Basic): ~$5
- Log Analytics (1GB/day): ~$3
- LoadBalancer IPs (3): ~$15
- **Total: ~$83/month**

To minimize costs:
- Delete resources when not in use
- Use `az aks stop` to deallocate nodes (preserves configuration)
- Scale down to 1 node for testing

## Security Notes

- **Change Grafana password** in `k8s/grafana.yaml` before production use
- LoadBalancer services expose public IPs - restrict with Network Security Groups
- Enable RBAC and Azure AD integration for production clusters
- Use Azure Key Vault for secrets management
- Consider using Ingress controller with TLS instead of LoadBalancer services

## Next Steps

1. Explore Prometheus queries using `PROMETHEUS_QUERIES.md`
2. Create custom Grafana dashboards
3. Add more sample applications with metrics
4. Configure alerting rules in Prometheus
5. Integrate with Azure Monitor for hybrid monitoring

## Resources

- [Prometheus Documentation](https://prometheus.io/docs/)
- [Grafana Documentation](https://grafana.com/docs/)
- [AKS Documentation](https://docs.microsoft.com/en-us/azure/aks/)
- [PromQL Basics](https://prometheus.io/docs/prometheus/latest/querying/basics/)
