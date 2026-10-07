# Session 21: Final DevOps Project — Taskboard

> **Student:** Radhey Kawasthi (Enrollment: 10242)

An end-to-end DevOps capstone: a Python **Taskboard** app taken through the full journey — code → tests → Docker → security scans → registry → Kubernetes (probes/HPA/storage/config) → Helm → Terraform infra → monitoring → GitOps — plus a real troubleshooting drill.

## Project overview

```text
Application (python http server + unittest)
     ↓ git push
GitHub (this repo)
     ↓
CI Pipeline (GitHub Actions: test → security → build → push)
     ↓
Docker Image → ghcr.io/rkawasthiii/taskboard
     ↓
Kubernetes (Deployment, Service, ConfigMap, Secret, Ingress, HPA, probes, PVC)
     ↓                            ↘
Helm chart (helm/taskboard)      Terraform (S3 + SG + EC2)
     ↓
Monitoring (/healthz, /readyz, metrics-server, probes, alerts doc)
     ↓
GitOps (ArgoCD Application syncs kubernetes/manifests)
```

## Repo layout

| Folder | Contents |
| :--- | :--- |
| `application/` | `app/main.py` — stdlib HTTP server (`/`, `/api/tasks`, `/healthz`, `/readyz`) + `tests/` + `requirements.txt` |
| `docker/` | multi-stage `Dockerfile` — build stage **runs the tests inside the image**, runtime stage is slim + `USER nobody` |
| `kubernetes/manifests/` | Deployment (probes, resources, env from ConfigMap+Secret), Service, Ingress, HPA, PVC, ConfigMap, Secret |
| `helm/taskboard/` | real `helm create` chart, tuned to taskboard (port 8000, /healthz+/readyz probes) — `helm lint` clean, `helm template` verified |
| `terraform/` | S3 bucket + Security Group + EC2 (`init`/`fmt`/`validate` executed; apply needs AWS creds) |
| `.github/workflows/` | `final-pipeline.yml` — test → security scans → build/scan/push → deploy |
| `security/` | DevSecOps controls inventory (SAST/SCA/secret/image scanning, gates, non-root) |
| `monitoring/` | health endpoints, Prometheus scrape config, Grafana dashboard plan |
| `gitops/` | ArgoCD `Application` manifest + explanation — automated self-healing sync |
| `troubleshooting/` | real broken→fixed drill on THIS app (ImagePullBackOff etc.) |

## Verified live (all real)

```text
# App unit tests ran INSIDE the docker build:
#10 [build 6/6] RUN python -m unittest discover -s tests -v ... OK

# Deployed to kind cluster (image loaded via `kind load`):
taskboard-5c85dd778d-p46bc   1/1   Running
taskboard-5c85dd778d-xll8w   1/1   Running

$ curl localhost:8006/          → <h1>Taskboard v1.0.0</h1>
$ curl localhost:8006/api/tasks → [{"id":1,"title":"Build CI pipeline",...}]
$ curl localhost:8006/healthz   → {"status": "healthy"}

$ kubectl get hpa taskboard
taskboard   Deployment/taskboard   cpu: <unknown>/60%   2   6   2
```

## Technologies used

Python • Docker (multi-stage) • Kubernetes (kind) • Helm • Terraform (AWS) • GitHub Actions • CodeQL • Trivy • Gitleaks • GHCR • metrics-server/HPA • ArgoCD (GitOps) • ingress-nginx

## CI/CD pipeline

[`.github/workflows/final-pipeline.yml`](.github/workflows/final-pipeline.yml) (executed copy at repo root `.github/workflows/session21-final.yml`):

```text
test (unittest) → security (gitleaks + trivy fs) → build-scan-push (docker + trivy image + GHCR) → deploy (manifest validation → GitOps handoff)
```

## DevSecOps implementation

See [`security/README.md`](security/README.md): SAST (CodeQL), SCA (Trivy fs), secret scanning (Gitleaks), container image scanning (Trivy image), security gate on CRITICAL count, non-root container, resource limits, S3 public-access-block.

## Infrastructure (Terraform)

[`terraform/`](terraform/) provisions the cloud side — S3 assets bucket (public access blocked), security group for the app, EC2 instance. `terraform init` + `validate` verified real; `apply` needs AWS credentials.

## GitOps

[`gitops/application.yaml`](gitops/application.yaml) — ArgoCD `Application` pointing at `kubernetes/manifests/` with `automated` sync, `prune`, and `selfHeal`. See [`gitops/README.md`](gitops/README.md).

## Troubleshooting

See [`troubleshooting/README.md`](troubleshooting/README.md) — three real issues hit and fixed on this app: `ImagePullBackOff` (missing image), service verification via port-forward, and HPA `<unknown>` metrics explanation.
