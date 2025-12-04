# AKS Deployment - Quick Start

## What's Ready

✅ **Bicep Infrastructure Templates**
- `infra/main-aks.bicep` - Main deployment template
- `infra/modules/aks-cluster.bicep` - AKS cluster configuration
- `infra/modules/acr-role-assignment.bicep` - ACR permissions for AKS
- `infra/modules/container-registry.bicep` - Azure Container Registry
- `infra/modules/log-analytics.bicep` - Log Analytics workspace

✅ **Kubernetes Manifests**
- `k8s/namespace.yaml` - Monitoring namespace
- `k8s/sample-app.yaml` - Flask app with Prometheus annotations (2 replicas)
- `k8s/prometheus.yaml` - Prometheus with Kubernetes pod discovery + RBAC
- `k8s/grafana.yaml` - Grafana with pre-configured Prometheus datasource

✅ **Deployment Scripts**
- `deploy-aks.ps1` - Full deployment automation
- `cleanup-aks.ps1` - Resource cleanup

✅ **Documentation**
- `AKS_DEPLOYMENT.md` - Complete deployment guide

## Deploy Now

```powershell
.\deploy-aks.ps1
```

This will:
1. Create Azure resource group
2. Deploy AKS cluster (2 nodes, Standard_B2s) - **~10-15 minutes**
3. Deploy Azure Container Registry
4. Build and push sample app image
5. Configure kubectl
6. Deploy Prometheus, Grafana, and sample app
7. Wait for LoadBalancer IPs
8. Display access URLs

## What You'll Get

- **Sample App**: Flask application at `http://<external-ip>`
  - Endpoints: `/api/data`, `/api/users`, `/api/health`, `/metrics`
  - 2 replicas for load balancing
  
- **Prometheus**: Metrics collection at `http://<external-ip>:9090`
  - Auto-discovers pods with `prometheus.io/scrape: "true"` annotation
  - Scrapes sample app every 15 seconds
  
- **Grafana**: Dashboard at `http://<external-ip>`
  - Username: `admin`
  - Password: `TestPassword123!`
  - Prometheus datasource pre-configured

## Key Improvements Over Container Apps

1. **Better service discovery** - Prometheus automatically finds pods
2. **Load balancing** - 2 sample app replicas behind Kubernetes service
3. **Production-like** - Real Kubernetes cluster vs serverless containers
4. **Scalability** - Easy to scale pods and nodes
5. **RBAC** - Proper permissions for Prometheus to discover pods

## Cost

~$83/month (2 nodes + ACR + Log Analytics + 3 LoadBalancers)

Delete when not in use:
```powershell
.\cleanup-aks.ps1
```

## Next Steps

1. Run `.\deploy-aks.ps1`
2. Open Grafana URL
3. Explore metrics using `PROMETHEUS_QUERIES.md`
4. Generate traffic with `.\generate-traffic.ps1`
5. Create custom dashboards

See `AKS_DEPLOYMENT.md` for detailed documentation.
