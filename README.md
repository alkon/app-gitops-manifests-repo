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
```

## 🔗 Exemplars & Observability Correlation

This repository implements comprehensive **exemplars support** throughout the observability stack, enabling seamless correlation between metrics, traces, and logs:

### Key Features

- **Latest Thanos Charts**: Updated to Bitnami v17.2.3 with Thanos v0.39.1 for enhanced exemplars support
- **End-to-End Correlation**: Direct navigation from dashboard metrics to trace details and back
- **Enhanced SpanMetrics**: Optimized OpenTelemetry collector configuration with better histogram buckets and dimensions
- **Exception Tracking**: Automatic capture of exception events in metrics for improved debugging

### Exemplars Flow

```text
Flask App → OTel Collector → Thanos Receiver → Thanos Query → Grafana
    ↓              ↓              ↓              ↓           ↓
Instrumented   SpanMetrics   Exemplars      Enhanced     Dashboard
 Metrics      Connector      Storage        Queries      Links
    ↓              ↓              ↓              ↓           ↓
Trace Context → Exemplars → Stored with → Query with → Click to
 Attached      Generated    Metrics      Exemplars     Tempo
```

### Dashboard → Tempo Integration

- **One-click navigation**: Click any metric point in Grafana dashboards to view related traces in Tempo
- **Automatic correlation**: Exemplars preserve trace context, enabling direct trace lookup
- **Bidirectional linking**: Tempo traces include links back to relevant dashboard charts

### Enhanced Configuration

- **Python Instrumentation**: TraceBased exemplar filtering with enriched span attributes
- **SpanMetrics Connector**: Optimized buckets, dimensions (`service.name`, `http.route`), and exception tracking
- **Thanos Components**: Exemplars enabled on both receiver (`--receive.exemplars=on`) and query (`--query.enable-exemplars`)
- **Grafana Datasources**: Configured with exemplar-to-trace correlation via Tempo integration

### Benefits

- **Reduced MTTR**: Direct correlation between metrics anomalies and specific traces
- **Better Debugging**: Exception events automatically captured and searchable
- **Improved Context**: HTTP headers, routes, and service information preserved
- **Seamless UX**: No context switching required between metrics and traces
