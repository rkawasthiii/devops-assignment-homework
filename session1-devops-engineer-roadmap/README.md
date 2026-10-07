# Session 1: DevOps Engineer Roadmap — Notes

> **Student:** Radhey Kawasthi (Enrollment: 10242)

Session 1 introduced what DevOps is and the roadmap to become a DevOps engineer.

## What is DevOps?

**DevOps** = **Dev**elopment + **Op**eration**s**. It is a culture + set of practices that removes the wall between the team that *writes* code and the team that *runs* it, so software can be built, tested, shipped, and operated **faster and more reliably**.

```text
Plan → Code → Build → Test → Release → Deploy → Operate → Monitor → (loop)
        |__________________ Continuous feedback __________________|
```

## The DevOps Engineer Roadmap (covered in this course)

| Stage | Skill | Where it appears in this repo |
| :--- | :--- | :--- |
| 1 | **Linux fundamentals** — OS, users, permissions, logs | `session2-linux/` |
| 2 | **Scripting** — Bash automation | `session3-shell-scripting/` |
| 3 | **Networking** — IP, DNS, ports, protocols | `session4-networking/` |
| 4 | **Version control** — Git & GitHub | `session5-git-github/` |
| 5 | **Containers** — Docker images, networking, volumes | `session6-7-docker/`, `session8-docker-networking-volume/` |
| 6 | **Container orchestration** — Kubernetes | `session9-k8s/` … `session-14-kubernetes-troubleshooting/` |
| 7 | **Package management** — Helm | `session-15-helm/` |
| 8 | **CI/CD** — GitHub Actions pipelines | `session-16-github-actions/` |
| 9 | **DevSecOps** — security inside the pipeline | `session-17-devsecops/` |
| 10 | **Infrastructure as Code** — Terraform + AWS | `session18-terraform-iac/`, `session19-cloud-terraform/` |
| 11 | **Observability & GitOps** — metrics/logs/traces, ArgoCD | `session20-monitoring-observability-gitops/` |
| 12 | **Capstone** — end-to-end project | `session21-python/` |

## Key takeaways

* DevOps is about **automation + feedback loops**, not just tools.
* Everything is **code**: application code, infrastructure (Terraform), pipelines (GitHub Actions), deployments (Helm/Kubernetes YAML).
* The goal: ship small changes **continuously and safely**.

➡️ The Linux hands-on homework for Sessions 1 & 2 lives in [`../session2-linux/README.md`](../session2-linux/README.md).
