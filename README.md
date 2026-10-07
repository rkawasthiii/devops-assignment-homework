# devops-assignment-homework

> **Radhey Kawasthi — Enrollment: 10242**
>
> Complete DevOps homework covering all 21 sessions: Linux → Shell → Networking → Git → Docker → Kubernetes → Helm → CI/CD → DevSecOps → Terraform/AWS → Monitoring/GitOps → Final Project.
>
> Every task was performed **for real**: commands were executed on a local `kind` Kubernetes cluster (v1.35), Docker Desktop, Helm v4, and Terraform v1.16.5 — actual outputs are embedded in each README.

## Session Index

| Session | Topic | README |
| :--- | :--- | :--- |
| 1 & 2 | DevOps Roadmap + Linux Fundamentals (links, adduser/useradd, journalctl, cheat sheet) | [`session2-linux/README.md`](session2-linux/README.md) · [`session1-devops-engineer-roadmap/README.md`](session1-devops-engineer-roadmap/README.md) |
| 3 | Shell Scripting (system-info script) | [`session3-shell-scripting/README.md`](session3-shell-scripting/README.md) |
| 4 | Networking (IP classes + real command outputs) | [`session4-networking/README.md`](session4-networking/README.md) |
| 5 | Git & GitHub (`commit -a -m`, cherry-pick) | [`session5-git-github/README.md`](session5-git-github/README.md) |
| 6 | Docker Fundamentals (6 hello-world apps, all live-verified) | [`session6-7-docker/README.md`](session6-7-docker/README.md) |
| 7 | Docker Images (multi-stage build + deployment) | [`session6-7-docker/README.md`](session6-7-docker/README.md) |
| 8 | Docker Networking & Volumes (3-tier nets, host net, bind mount, overlay) | [`session8-docker-networking-volume/README.md`](session8-docker-networking-volume/README.md) |
| 9 | Kubernetes Fundamentals (cluster, architecture, basics tutorial) | [`session9-k8s/README.md`](session9-k8s/README.md) |
| 10 | K8s Pods/RS/Deployments (4 strategies + pod lifecycle) | [`session10-k8s-core-objects/README.md`](session10-k8s-core-objects/README.md) |
| 11 | K8s Networking & Services (5 types, FQDN, CoreDNS, comparisons) | [`session-11-kubernetes-services/README.md`](session-11-kubernetes-services/README.md) |
| 12 | Ingress, ConfigMaps & Secrets (+ troubleshooting) | [`session-12-ingress-configmaps-secrets/README.md`](session-12-ingress-configmaps-secrets/README.md) |
| 13 | Storage, HPA & Probes (+ mini project) | [`session-13-storage-hpa-probes/README.md`](session-13-storage-hpa-probes/README.md) |
| 14 | Kubernetes Troubleshooting (5 scenarios + 3-bug mini project) | [`session-14-kubernetes-troubleshooting/README.md`](session-14-kubernetes-troubleshooting/README.md) |
| 15 | Helm (commands, install→upgrade→rollback, mini project) | [`session-15-helm/README.md`](session-15-helm/README.md) |
| 16 | CI/CD & GitHub Actions (live pipeline) | [`session-16-github-actions/README.md`](session-16-github-actions/README.md) |
| 17 | Complete CI/CD & DevSecOps (7-stage pipeline) | [`session-17-devsecops/README.md`](session-17-devsecops/README.md) |
| 18 | Terraform & IaC (S3 demo + 5 AWS service deep-dives) | [`session18-terraform-iac/README.md`](session18-terraform-iac/README.md) |
| 19 | Cloud & Terraform in Action (VPC→EC2→S3 project) | [`session19-cloud-terraform/README.md`](session19-cloud-terraform/README.md) |
| 20 | Monitoring, Observability & GitOps | [`session20-monitoring-observability-gitops/README.md`](session20-monitoring-observability-gitops/README.md) |
| 21 | Final DevOps Project — Taskboard | [`session21-python/README.md`](session21-python/README.md) |

## Environment used

* **OS:** Windows + Docker Desktop (WSL2); Linux tasks run in Ubuntu 22.04 containers
* **Kubernetes:** `kind` cluster `devops-hw` (K8s v1.35, ingress-nginx, metrics-server)
* **Tools:** kubectl v1.36 • helm v4.1.3 • terraform v1.16.5 • docker v29.6.2 • gh CLI
* **CI/CD:** GitHub Actions workflows at [`.github/workflows/`](.github/workflows/) execute on push — see the Actions tab for real runs
