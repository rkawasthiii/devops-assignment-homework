# GitOps — Taskboard Final Project

Git is the single source of truth: `session21-python/kubernetes/manifests/` IS the desired production state. [`application.yaml`](./application.yaml) is the ArgoCD `Application` CRD that wires the repo to the cluster:

* **`automated` sync** — a merge to `main` deploys automatically; no `kubectl` from laptops or CI.
* **`prune: true`** — removing a manifest from Git removes it from the cluster.
* **`selfHeal: true`** — manual `kubectl edit` drift gets reverted to match Git.
* **Rollback** = `git revert` the offending commit → ArgoCD converges back.

```text
PR merged → ArgoCD polls (or webhook) → diff detected → apply → cluster == Git
```

Install flow in production: `kubectl apply -n argocd -f application.yaml` after ArgoCD is installed (`helm install argocd argo/argo-cd`).
