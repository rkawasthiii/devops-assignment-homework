# Session 10: Kubernetes Pods, ReplicaSets & Deployments — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)
>
> Cluster: `kind-devops-hw` (Kubernetes v1.35). All commands executed for real — actual output shown in each subfolder's README.

## Task 1: The 4 Deployment Strategies

| Strategy | Folder | One-line idea |
| :--- | :--- | :--- |
| **Rolling Update** (default) | [`01-rolling-update/`](./01-rolling-update/) | Replace Pods a few at a time — zero downtime |
| **Blue-Green** | [`02-blue-green/`](./02-blue-green/) | Two full environments; flip the Service selector to switch instantly |
| **Canary** | [`03-canary/`](./03-canary/) | Route a small % of traffic to the new version via 1 canary Pod |
| **Recreate** | [`04-recreate/`](./04-recreate/) | Kill ALL old Pods first, then create new — brief downtime |

## Task 2: Pod Lifecycle

See [`pod-lifecycle/README.md`](./pod-lifecycle/) — demonstrated **Running**, **Completed/Succeeded**, and **Error → CrashLoopBackOff** states on real Pods.

```text
Pending → ContainerCreating → Running ─→ Succeeded (exit 0)
                                 └────→ Failed / CrashLoopBackOff (exit ≠ 0, restarted with backoff)
```

## Quick comparison of the strategies

| | Downtime | Traffic split | Rollback speed | Resource cost |
| :--- | :--- | :--- | :--- | :--- |
| RollingUpdate | none | gradual | fast (`rollout undo`) | low (surge ≤1 pod) |
| Blue-Green | none | all-or-nothing | **instant** (selector flip) | **2x** pods |
| Canary | none | weighted by pod count | fast (delete canary) | +1 pod |
| Recreate | **yes (window)** | none | slow | none |
