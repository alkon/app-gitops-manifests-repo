# GitOps Manifests for Platform Apps

This repository contains Helm-based application manifests designed for GitOps-based deployment through Argo CD. It complements a Terraform project that provisions `argocd_server` and manages `argocd_app` modules that consume these manifests.

## Structure
Each subdirectory under `platform-apps/` corresponds to a Helm chart representing an infrastructure or observability component:
```text
platform-apps/
├── cert-manager # Certs for TLS and Argo CD webhook validation
├── flask-simulator # Load generator: hits Flask app's /checkout
├── grafana # Dashboards and visualizations
│ └── dashboards/ # JSON definitions of dashboards (RED, traces, etc.)
├── otel-collector # Receives and exports telemetry
├── otel-config # Injection rules for instrumentation
├── otel-operator # OTel Instrumentation Operator
├── tempo # Trace backend storage for Tempo
├── thanos-query # Prometheus-compatible query engine
├── thanos-receiver # Remote write receiver from collectors
```
## 🚀 Usage

Each directory can be used with Argo CD via Terraform (for example):

```hcl
module "argocd_app_otel_collector" {
  source        = "./modules/argocd-app"
  chart_path    = "platform-apps/otel-collector"
  repo_url      = "https://github.com/alkon/app-gitops-manifests-repo.git"
  repo_revision = "HEAD"
}