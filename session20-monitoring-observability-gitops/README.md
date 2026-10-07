# Session 20: Monitoring, Observability & GitOps — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Cluster: `kind-devops-hw` + metrics-server

---

## Task 1: Monitoring — real demo

**Monitoring** = collecting predefined signals to answer known questions: *"is CPU high? is the pod alive?"*

### Metrics (real output)

A `stress-demo` pod was run in a CPU-burn loop, then observed:

```bash
$ kubectl top nodes
devops-hw-control-plane   1367m   34%   1051Mi   13%     # node CPU/mem utilization

$ kubectl top pod stress-demo
stress-demo   872m   0Mi                                # the busy pod, burning 0.87 cores
```

### Logs

```bash
$ kubectl logs stress-demo --tail=5
$ kubectl logs <pod> -f                    # follow
$ kubectl logs <pod> --previous            # last crashed container
```

### Alerts & health signals

```bash
$ kubectl get events --field-selector reason=Unhealthy
Warning Unhealthy pod/app-rolling-...   Readiness probe failed: connect: connection refused
Warning Unhealthy pod/probes-demo       Readiness probe failed: connect: connection refused
```

Probes are Kubernetes' built-in health monitoring — `readiness` removes the pod from Service endpoints, `liveness` restarts it. On top: Prometheus Alertmanager sends to Slack/PagerDuty/email.

### Application health

```bash
$ kubectl get pods             # READY column = health at a glance
$ kubectl describe pod <p>     # Last State / Restart Count / events
$ kubectl top pod <p>          # resource pressure
```

**Monitoring stack reference:** Prometheus (metrics collection + PromQL + alerting) → Grafana (dashboards) → Alertmanager (notifications); metrics-server feeds `kubectl top` + HPA; Loki/EFK for logs.

---

## Task 2: Observability — the three pillars

**Observability** = understanding *why* a system misbehaves from its outputs — including questions you didn't anticipate. Monitoring asks known questions; observability lets you ask new ones.

| Pillar | What it is | Question it answers | Tools |
| :--- | :--- | :--- | :--- |
| **Metrics** | numeric time-series (CPU%, req/sec, error-rate, p99 latency) | *"How much / how many?"* | Prometheus, Grafana, metrics-server, Datadog |
| **Logs** | timestamped event records | *"What happened, in what order?"* | Loki, ELK/EFK, `kubectl logs`, CloudWatch |
| **Traces** | one request's journey across services (spans) | *"WHERE is it slow/broken across the call chain?"* | Jaeger, Tempo, Zipkin, OpenTelemetry |

```text
Metrics  → "error rate spiked to 12%"          (symptom)
Logs     → "payment-service: DB timeout at 14:02:11"  (detail)
Traces   → "the /checkout span waits 2.3s on payment → db"  (root cause location)
```

### Why observability is required

* Microservices = distributed failures; a single user click fans out to 10+ services
* Dashboards only catch **known-unknowns**; real incidents are **unknown-unknowns** — you need correlated metrics+logs+traces to investigate
* SLIs/SLOs need metrics; postmortems need logs+traces

### Kubernetes observability

* Metrics: metrics-server (resource), kube-state-metrics (object states), cAdvisor (per-container)
* Logs: stdout/stderr per container → node agents (fluent-bit DaemonSet) → backend
* Traces: app instrumentation (OTel SDK) or service-mesh (Istio/Linkerd auto-trace)
* Common stack: **Prometheus + Grafana + Loki + Tempo + OTel collector**

---

## Task 3: GitOps — real concept + repo layout

**GitOps** = Git is the **single source of truth** for infrastructure+app state. A controller in the cluster continuously pulls the repo and reconciles reality to match — nobody runs `kubectl apply` by hand in prod.

### The four principles

| Principle | Meaning |
| :--- | :--- |
| **Declarative** | desired state described as YAML/Helm/Kustomize — not scripts of commands |
| **Git = source of truth** | versioned, audited, reviewable; `git log` IS the change history |
| **Pulled automatically** | agent (ArgoCD/Flux) watches the repo + applies — no creds leave the cluster |
| **Continuous reconciliation** | drift (manual `kubectl edit`, deleted resource) is detected + corrected |

### GitOps workflow

```text
dev commits manifest ──► PR review/merge ──► ArgoCD/Flux polls repo
        ▲                                        │
   git revert = rollback              detects diff → applies → cluster converges
   (infrastructure change = a commit)              │
                                   manual kubectl edit? → reverted to match Git
```

### Kubernetes + GitOps

* **ArgoCD** — GUI + app-of-apps, health/status sync visuals
* **FluxCD** — GitOps toolkit, image-automation
* A live GitOps "repo" layout is included at [`gitops-repo/`](./gitops-repo/) — ArgoCD would point at `gitops-repo/app/` and keep `deployment.yaml` + `service.yaml` applied continuously

### Benefits

* Disaster recovery = re-point the repo at a fresh cluster
* Audit: every production change has an author, reviewer, timestamp
* Rollback = `git revert` (tested, reviewed) instead of hot-fix commands
* No cluster credentials in CI pipelines — the agent pulls

---

## Key takeaways

* Monitoring = **known questions, predefined signals**; Observability = **new questions via metrics+logs+traces**
* GitOps = **Git as the source of truth + a controller that converges the cluster to it**
