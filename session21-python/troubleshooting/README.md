# Final Troubleshooting Challenge — Taskboard

Issues intentionally present/encountered while deploying this project, each documented as: **identify → investigate → root cause → fix → verify**.

---

## Issue 1: Pods stuck in `ImagePullBackOff`

### Identify

```bash
$ kubectl apply -f kubernetes/manifests/
$ kubectl get pods | grep taskboard
taskboard-965df5d8-c92m9   0/1   ImagePullBackOff   0   25s
taskboard-965df5d8-dqv6x   0/1   ImagePullBackOff   0   25s
```

### Investigate

```bash
$ kubectl describe pod -l app=taskboard
Warning  Failed: Failed to pull image "ghcr.io/rkawasthiii/taskboard:latest":
         ... not found
```

### Root cause

The manifest points at `ghcr.io/rkawasthiii/taskboard:latest`, which did not exist yet — the CI/CD pipeline that builds and pushes it hadn't run. Also, `latest` tag + default `IfNotPresent`... the pull itself failed because the repo/package isn't published.

### Fix

For the local kind cluster, the image was built locally (`docker build -t taskboard:local`), loaded via `kind load docker-image taskboard:local`, and the Deployment pointed at it:

```bash
kubectl set image deployment/taskboard app=taskboard:local
kubectl patch deployment taskboard --type='json' \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/imagePullPolicy","value":"IfNotPresent"}]'
```

(In production the fix is the pipeline: `build-scan-push` job publishes `ghcr.io/rkawasthiii/taskboard:latest` — no manifest change needed.)

### Verify

```text
$ kubectl rollout status deployment/taskboard
deployment "taskboard" successfully rolled out
taskboard-5c85dd778d-p46bc   1/1   Running
taskboard-5c85dd778d-xll8w   1/1   Running
$ kubectl get endpoints taskboard
taskboard   10.244.0.99:8000,10.244.0.100:8000
```

---

## Issue 2: Service reachable? — port-forward end-to-end check

### Verify application through the Service

```bash
$ kubectl port-forward svc/taskboard 8006:80
$ curl http://localhost:8006/
<h1>Taskboard v1.0.0</h1>

$ curl http://localhost:8006/api/tasks
[{"id":1,"title":"Build CI pipeline","done":true}, ...]

$ curl http://localhost:8006/healthz
{"status": "healthy"}
```

All 3 endpoints respond — app + Service + endpoints chain confirmed working.

## Issue 3: HPA registered but shows `<unknown>` metric

### Identify

```text
$ kubectl get hpa taskboard
taskboard   Deployment/taskboard   cpu: <unknown>/60%   2   6   2
```

### Investigate / Root cause

HPA needs **metrics-server** to read pod CPU. Right after deployment, no metric sample exists yet — `<unknown>` is normal for ~60s. The `FailedGetResourceMetric` event appears until the first scrape.

### Fix / Verify

metrics-server was already installed (`kubectl top pods` returns data); the `resources.requests.cpu: 50m` field in `deployment.yaml` is what the 60% target is measured against — after a scrape cycle the column fills with a real percentage. Without `requests` set, HPA can never scale.

---

## Lessons (the order that actually finds things)

1. `kubectl get` shows the **symptom** (`ImagePullBackOff`, `<none>` endpoints)
2. `kubectl describe` shows **why the cluster can't proceed** (pull errors, scheduling)
3. `kubectl logs` shows **why the app misbehaves**
4. Fix the **outermost layer first** — image → config → scheduling → networking — because inner bugs hide behind outer ones
