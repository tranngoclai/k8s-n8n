# n8n Kubernetes Deployment with SeleniumBase API

This Helm chart deploys n8n workflow automation along with additional services:
- **n8n**: Workflow automation platform
- **Browserless Chrome**: Headless Chrome for Playwright and web scraping
- **SeleniumBase API**: FastAPI server for executing SeleniumBase web scraping scripts

## Prerequisites

- Kubernetes cluster (v1.19+)
- Helm 3.x
- kubectl configured to access your cluster

## Installation

### 1. Build and Push the SeleniumBase API Docker Image

First, build the SeleniumBase API Docker image from the SeleniumBase project:

```bash
cd ../SeleniumBase
docker build -t your-registry/seleniumbase-api:latest .
docker push your-registry/seleniumbase-api:latest
```

Update the image repository in `values.yaml`:

```yaml
seleniumbase:
  image:
    repository: your-registry/seleniumbase-api
    tag: "latest"
```

### 2. Install Helm Dependencies

```bash
cd k8s-n8n
helm dependency update
```

### 3. Install the Chart

```bash
helm install n8n-deployment . -f values.yaml
```

Or with custom values:

```bash
helm install n8n-deployment . -f values.yaml -f custom-values.yaml
```

### 4. Upgrade an Existing Release

```bash
helm upgrade n8n-deployment . -f values.yaml
```

## Configuration

### SeleniumBase API Configuration

The SeleniumBase API can be configured through the `seleniumbase` section in `values.yaml`:

```yaml
seleniumbase:
  enabled: true
  replicaCount: 1

  image:
    repository: your-registry/seleniumbase-api
    tag: "latest"
    pullPolicy: IfNotPresent

  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
    requests:
      cpu: 500m
      memory: 1Gi

  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 5
```

### Accessing SeleniumBase API

By default, the SeleniumBase API is exposed as a ClusterIP service. To access it:

#### From within the cluster:

```
http://n8n-deployment-seleniumbase:8000
```

#### Using port-forward:

```bash
kubectl port-forward svc/n8n-deployment-seleniumbase 8000:8000
```

Then access at `http://localhost:8000`

#### Enable Ingress:

Update `values.yaml`:

```yaml
seleniumbase:
  ingress:
    enabled: true
    className: "nginx"
    annotations:
      cert-manager.io/cluster-issuer: "letsencrypt-prod"
    hosts:
      - host: seleniumbase-api.yourdomain.com
        paths:
          - path: /
            pathType: Prefix
    tls:
      - secretName: seleniumbase-api-tls
        hosts:
          - seleniumbase-api.yourdomain.com
```

## SeleniumBase API Usage

### API Endpoints

- `GET /health` - Health check endpoint
- `POST /submit` - Submit a Python scraping script for execution
- `GET /status/{job_id}` - Get job status
- `GET /result/{job_id}` - Get job results with artifacts and logs
- `GET /artifacts/{job_id}/{filename}` - Download specific artifact
- `DELETE /job/{job_id}` - Clean up job and artifacts

### Example: Submit a Scraping Job

```bash
curl -X POST http://localhost:8000/submit \
  -F "file=@your_script.py"
```

Example script (`your_script.py`):

```python
from seleniumbase import SB

with SB(headless=True) as sb:
    sb.open("https://example.com")
    sb.save_screenshot_to_logs("example.png")
    print("Title:", sb.get_page_title())
```

Response:

```json
{
  "job_id": "abc123",
  "status": "pending",
  "message": "Job submitted successfully"
}
```

### Check Job Status

```bash
curl http://localhost:8000/status/abc123
```

### Get Job Results

```bash
curl http://localhost:8000/result/abc123
```

### Download Artifacts

```bash
curl http://localhost:8000/artifacts/abc123/example.png -o example.png
```

## Integration with n8n

You can use the SeleniumBase API from n8n workflows using HTTP Request nodes:

1. **Submit Job**: POST to `/submit` with Python script file
2. **Poll Status**: GET `/status/{job_id}` until status is "completed"
3. **Retrieve Results**: GET `/result/{job_id}` to get logs and artifact paths
4. **Download Artifacts**: GET `/artifacts/{job_id}/{filename}` for each artifact

## Resource Management

### Autoscaling

Enable horizontal pod autoscaling for SeleniumBase API:

```yaml
seleniumbase:
  autoscaling:
    enabled: true
    minReplicas: 1
    maxReplicas: 5
    targetCPUUtilizationPercentage: 80
    targetMemoryUtilizationPercentage: 80
```

### Resource Limits

Adjust based on your workload:

```yaml
seleniumbase:
  resources:
    limits:
      cpu: 2000m
      memory: 4Gi
    requests:
      cpu: 500m
      memory: 1Gi
```

## Monitoring

### Prometheus Integration

Enable ServiceMonitor for Prometheus:

```yaml
seleniumbase:
  serviceMonitor:
    enabled: true
    interval: 30s
    labels:
      release: prometheus
```

## Troubleshooting

### Check Pod Status

```bash
kubectl get pods -l app.kubernetes.io/component=seleniumbase-api
```

### View Logs

```bash
kubectl logs -l app.kubernetes.io/component=seleniumbase-api -f
```

### Describe Pod

```bash
kubectl describe pod <seleniumbase-pod-name>
```

### Common Issues

1. **ImagePullBackOff**: Ensure the Docker image is built and pushed to the registry
2. **CrashLoopBackOff**: Check logs for startup errors
3. **Out of Memory**: Increase memory limits in `resources`
4. **Slow execution**: Increase CPU/memory or enable autoscaling

## Uninstallation

```bash
helm uninstall n8n-deployment
```

To also remove persistent volumes:

```bash
kubectl delete pvc -l app.kubernetes.io/instance=n8n-deployment
```

## Architecture

```
┌─────────────────────────────────────────────────┐
│              Kubernetes Cluster                  │
│                                                  │
│  ┌──────────────┐  ┌─────────────────────────┐ │
│  │     n8n      │  │  SeleniumBase API       │ │
│  │   Workflow   │──│  FastAPI Server         │ │
│  │  Automation  │  │  (Port 8000)            │ │
│  │              │  │                         │ │
│  └──────┬───────┘  └─────────────────────────┘ │
│         │                                        │
│  ┌──────▼──────────────┐                       │
│  │  Browserless Chrome  │                       │
│  │  (Playwright/CDP)    │                       │
│  │  (Port 3000)         │                       │
│  └─────────────────────┘                       │
│                                                  │
│  ┌─────────────┐  ┌──────────┐                 │
│  │ PostgreSQL  │  │  Redis   │                 │
│  └─────────────┘  └──────────┘                 │
│                                                  │
└─────────────────────────────────────────────────┘
```

## License

This configuration is provided as-is for deploying n8n and SeleniumBase API on Kubernetes.

## Support

For issues related to:
- **n8n**: https://github.com/n8n-io/n8n
- **SeleniumBase**: https://github.com/seleniumbase/SeleniumBase
- **This Helm chart**: Open an issue in your repository
