# Session 12: Kubernetes Ingress, ConfigMaps & Secrets — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Cluster: `kind-devops-hw` + ingress-nginx controller

---

## Task 1: ConfigMap — real demo

[`01-configmap/configmap.yaml`](./01-configmap/configmap.yaml) — stores `APP_ENV`, `APP_COLOR`, `DATABASE_HOST` plus a `database.conf` file, injected 3 ways.

```bash
$ kubectl apply -f 01-configmap/configmap.yaml
configmap/app-config created
pod/configmap-demo created

$ kubectl get configmap app-config
app-config   4   # 4 keys stored
```

**Injected as env vars (single key + `envFrom` all keys):**

```bash
$ kubectl exec configmap-demo -- env | grep -E "APP_ENV|APP_COLOR|DATABASE_HOST"
APP_COLOR=blue
APP_ENV=production
DATABASE_HOST=db.internal.svc
```

**Injected as mounted files** (`volumes.configMap` → `/etc/app-config/`):

```bash
$ kubectl exec configmap-demo -- cat /etc/app-config/database.conf
max_connections=100
timeout=30
$ kubectl exec configmap-demo -- cat /etc/app-config/APP_COLOR
blue
```

ConfigMaps = **non-sensitive** config decoupled from the image. Edit the ConfigMap → new Pods pick it up (env vars need restart; mounted volumes update automatically).

---

## Task 2: Secret — real demo

[`02-secret/secret.yaml`](./02-secret/secret.yaml) — `DB_USER` / `DB_PASS` stored **base64-encoded**, injected via `secretKeyRef`.

```bash
$ kubectl apply -f 02-secret/secret.yaml
secret/db-secret created
pod/secret-demo created

$ kubectl get secret db-secret
db-secret   Opaque   2
```

**Values decoded automatically inside the container:**

```bash
$ kubectl exec secret-demo -- sh -c 'echo "DB_USER=$DB_USER  DB_PASS=$DB_PASS"'
DB_USER=admin  DB_PASS=Sup3rS3cret!
```

**Why Secrets must not be committed to Git directly:** base64 is *encoding, not encryption* — anyone can decode `U3VwM3JTM2NyZXQh` in seconds. A Secret in Git is a plaintext password in history forever. In production: use `stringData` + `.gitignore`, or external secret managers (AWS Secrets Manager, Vault, SealedSecrets/ESO). The `secret.yaml` here uses throwaway demo creds only.

| ConfigMap vs Secret | |
| :--- | :--- |
| Data | plaintext / base64-encoded |
| etcd storage | plain / encryption-at-rest possible (`EncryptionConfiguration`) |
| Use for | ports, flags, URLs / passwords, tokens, TLS keys |

---

## Task 3: Ingress — real demo

Stack: 2 nginx Pods + ClusterIP Service + Ingress rule for host `webapp.local`, routed by the **ingress-nginx controller** ([`03-ingress/app.yaml`](./03-ingress/app.yaml)).

```bash
$ kubectl apply -f 03-ingress/app.yaml
$ kubectl get ingress
NAME             CLASS   HOSTS          ADDRESS   PORTS
webapp-ingress   nginx   webapp.local             80

$ kubectl describe ingress webapp-ingress
Rules:  webapp.local   /   webapp-service:80 (10.244.0.53:80,10.244.0.52:80)
Events: Normal  Sync  nginx-ingress-controller  Scheduled for sync
```

**Access through the Ingress** (kind maps host `:9080` → node `:80` where the controller listens; `Host` header stands in for the DNS entry):

```bash
$ curl -H "Host: webapp.local" http://localhost:9080
<title>Welcome to nginx!</title>
```

```text
browser ──Host: webapp.local──► ingress-nginx-controller ──► webapp-service:80 ──► pod x2
```

---

## Task 4: Ingress vs Ingress Controller

| | **Ingress** | **Ingress Controller** |
| :--- | :--- | :--- |
| What | A **YAML resource** (`kind: Ingress`) — the *rules*: host, path → service | A **running pod** (nginx, Traefik, HAProxy...) — the *engine* that reads rules and routes traffic |
| Analogy | The traffic law written in a book | The traffic cop actually standing at the intersection |
| Does it work alone? | ❌ Without a controller, Ingress objects do **nothing** | Can route, but needs Ingress objects (or its own CRDs) to know the rules |
| Needed because | Declarative HTTP routing (host/path) instead of one LoadBalancer per app | Someone must terminate HTTP and dispatch — k8s ships no default controller |
| Examples | `webapp-ingress` above | `ingress-nginx`, Traefik, Kong, AWS ALB Controller, Istio Gateway |

**Why both are required:** the Ingress *declares* "send `webapp.local/` to `webapp-service:80`"; the ingress-nginx controller *watches* the API server, renders that into its nginx config, and performs the actual proxying (seen live in the `Sync` event above). One controller can serve thousands of Ingress rules behind a single entry point.

---

## Task 5: Troubleshooting — found, fixed, verified

Scenario in [`troubleshooting/broken-pod.yaml`](./troubleshooting/broken-pod.yaml): pod stuck at startup.

```bash
$ kubectl get pod broken-env-pod
broken-env-pod   0/1   CreateContainerConfigError   0   8s

$ kubectl describe pod broken-env-pod        # <-- investigation
Events:
  Warning  Failed  kubelet  spec.containers{app}: Error: configmap "app-settings" not found
```

* **Problem:** Pod won't start — `CreateContainerConfigError`.
* **Investigate:** `describe` → event says it references ConfigMap `app-settings`.
* **Root cause:** the ConfigMap is actually named `app-config` — a name mismatch in `configMapKeyRef`.
* **Fix:** corrected the reference to `app-config` ([`troubleshooting/fixed-pod.yaml`](./troubleshooting/fixed-pod.yaml)).
* **Verify:**

```bash
$ kubectl get pod fixed-env-pod
fixed-env-pod   1/1   Running   0   8s
$ kubectl logs fixed-env-pod
hello from configmap
```
