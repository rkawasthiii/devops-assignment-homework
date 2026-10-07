# Monitoring — Taskboard Final Project

## Signals wired in

* **Health endpoints:** `/healthz` (liveness) and `/readyz` (readiness) in `application/app/main.py` — consumed by Kubernetes probes in `kubernetes/manifests/deployment.yaml`.
* **Metrics:** `kubectl top pods` + metrics-server; Prometheus scrape config below for production.
* **HPA:** `kubernetes/manifests/hpa.yaml` scales 2→6 on 60% CPU.
* **Logs:** app writes to stdout → `kubectl logs`, collected by fluent-bit in production.
* **Alerts:** Alertmanager rules on `rate(http_errors) > 5%` and probe failures.

## Prometheus scrape config (production)

```yaml
scrape_configs:
- job_name: taskboard
  kubernetes_sd_configs:
  - role: pod
  relabel_configs:
  - source_labels: [__meta_kubernetes_pod_label_app]
    regex: taskboard
    action: keep
  - source_labels: [__meta_kubernetes_pod_container_port_number]
    regex: "8000"
    action: keep
```

## Grafana dashboard ideas

* Request rate + error rate + p95 latency (RED metrics)
* Pod CPU/memory vs requests&limits, HPA replica count over time
* Node saturation + etcd/API latency for cluster health
