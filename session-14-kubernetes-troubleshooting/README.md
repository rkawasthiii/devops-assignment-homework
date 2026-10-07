# Session 14: Kubernetes Troubleshooting — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Cluster: `kind-devops-hw`
>
> Every problem below was reproduced for real, investigated, root-caused, fixed, and verified.

---

## Task 1: Troubleshooting commands — hands-on

Real output on a live pod (`web-backend-67cb9fdd99-tgmh5`):

| Command | What it tells you | Real output |
| :--- | :--- | :--- |
| `kubectl get pods -o wide` | status, restarts, **pod IP + which node** | `Running  10.244.0.73  devops-hw-control-plane` |
| `kubectl describe pod <p>` | full spec + **Events** (scheduling, pulls, probe failures) — first stop for stuck pods | `Node: devops-hw-control-plane/172.20.0.2`, `Status: Running` |
| `kubectl logs <p>` | container stdout/stderr — why the *app* crashed | `2026/10/07 18:41:54 [notice] 1#1: start worker process` |
| `kubectl logs <p> --previous` | logs of the *last* crashed container (CrashLoop cases) | — |
| `kubectl exec <p> -- <cmd>` | run a command inside the container | `hostname` → `web-backend-67cb9fdd99-tgmh5` |
| `kubectl get events --sort-by=.lastTimestamp` | cluster-wide event stream | `Warning BackOff ... Back-off restarting failed container app` |
| `kubectl explain <resource.field>` | built-in API docs | `kubectl explain pod.spec.containers` → field description |
| `kubectl top pod/node` | CPU/memory usage (needs metrics-server) | `web-backend...  0m  4Mi` |

**Mental model:** `get` shows the *symptom*, `describe`/`events` show the *cluster's view* (scheduling, pulls, probes), `logs` shows the *app's view*, `exec` lets you *poke around inside*.

---

## Task 2: Common issues — reproduced → root-caused → fixed

Manifests in [`scenarios/`](./scenarios/).

### 1. CrashLoopBackOff / Error — the app itself dies

```text
$ kubectl get pod crashy
crashy   0/1   Error   RESTARTS: 2

$ kubectl logs crashy
app starting...
FATAL: config missing                 <-- the app exits non-zero on purpose

$ kubectl describe pod crashy
Reason: Error   Exit Code: 1   Restart Count: 2
```

* **Root cause:** container command `exit 1` — the app crashes, kubelet restarts with exponential backoff → `CrashLoopBackOff`/`Error`.
* **Fix:** corrected the command to exit `0` → pod `Completed` cleanly.
* **Real world:** check `--previous` logs, missing config/env, bad entrypoint, OOM.

### 2. ImagePullBackOff / ErrImagePull — bad image

```text
$ kubectl describe pod bad-image
Warning Failed: Failed to pull image "nginx:this-tag-does-not-exist":
  ... docker.io/library/nginx:this-tag-does-not-exist: not found
Warning Failed: Error: ErrImagePull
Warning Failed: Error: ImagePullBackOff
```

* **Root cause:** tag `this-tag-does-not-exist` doesn't exist on Docker Hub. `ErrImagePull` = first failure; `ImagePullBackOff` = retrying with backoff.
* **Fix:** `image: nginx:alpine` → `1/1 Running` in seconds.
* **Also check:** private registry credentials (`imagePullSecrets`), registry reachability, typos.

### 3. Pending — unschedulable

```text
$ kubectl describe pod stuck-pending
Warning FailedScheduling: 0/1 nodes are available:
  1 Insufficient cpu, 1 Insufficient memory. preemption: not helpful.
```

* **Root cause:** pod requests `cpu: 64, memory: 256Gi` — no node can ever satisfy it. Pod sits `Pending` forever (no `NODE`, no `IP`).
* **Fix:** requests → `cpu: 100m, memory: 64Mi` → scheduled instantly.
* **Also check:** node selectors/taints, PVC not bound, quota limits.

### 4. Service connectivity — `<none>` endpoints

```text
$ kubectl get endpoints web-backend-svc
web-backend-svc   <none>                     <-- Service found ZERO pods

$ kubectl describe svc web-backend-svc | grep Selector
Selector:  app=webbackend                    <-- service looks for 'webbackend'

$ kubectl get pod web-backend-... --show-labels
app=web-backend                              <-- pods are labelled 'web-backend'
```

* **Root cause:** selector `app=webbackend` ≠ pod label `app=web-backend` — one-character mismatch, silent failure.
* **Fix:** `kubectl patch svc` selector → `app=web-backend` → endpoints populated `10.244.0.73:80`.
* **This is the #1 service debugging step:** `kubectl get endpoints <svc>` — `<none>` always means selector/label/readiness mismatch.

### 5. Configuration issue — CreateContainerConfigError

```text
$ kubectl describe pod bad-config-pod
Warning Failed: couldn't find key APP_MODE_TYPO in ConfigMap default/app-config
Reason: CreateContainerConfigError
```

* **Root cause:** pod asks ConfigMap for key `APP_MODE_TYPO`; the ConfigMap only has `APP_MODE`.
* **Fix:** corrected key name → `1/1 Running`.
* **Also covers:** missing ConfigMap/Secret names, missing keys.

### 6. DNS / Pod networking issues — method

```bash
kubectl exec <pod> -- cat /etc/resolv.conf          # nameserver must be 10.96.0.10 (CoreDNS)
kubectl exec <pod> -- nslookup <svc>.<ns>.svc.cluster.local
kubectl -n kube-system get pods -l k8s-app=kube-dns  # CoreDNS alive?
kubectl get endpoints <svc>                          # backends exist?
```

Name resolves but connection fails → service/endpoints problem (not DNS). Name doesn't resolve → CoreDNS or wrong FQDN.

### Triage cheat sheet

| STATUS column | First command | Likely cause |
| :--- | :--- | :--- |
| `Pending` | `describe` → Events | resources/selector/taints/PVC |
| `ContainerCreating` | `describe` → Events | image pull slow, volume mount issue |
| `ImagePullBackOff`/`ErrImagePull` | `describe` → Failed | bad tag, private registry auth |
| `CreateContainerConfigError` | `describe` → Failed | missing configmap/secret/key |
| `CrashLoopBackOff`/`Error` | `logs --previous` | app crash, bad command, config |
| `Running` but unreachable | `get endpoints <svc>` | selector mismatch, wrong port, NetworkPolicy |
| `OOMKilled` | `describe` → Last State | memory limit too low |

---

## Task 3: Mini Project — 3-bug stack

[`mini-project/broken-stack.yaml`](./mini-project/broken-stack.yaml) deploys a shop-frontend with **three layered bugs**. [`mini-project/fixed-stack.yaml`](./mini-project/fixed-stack.yaml) is the corrected version.

**Bug 1 — ImagePullBackOff:**

```text
shop-frontend-6577755568-clk8k   0/1   ImagePullBackOff
fix: kubectl set image deployment/shop-frontend web=nginx:alpine
```

**Bug 2 — CreateContainerConfigError (surfaced only after bug 1 was fixed):**

```text
shop-frontend-7bc775454d-gbv65   0/1   CreateContainerConfigError
describe → couldn't find key "api-key" in secret "shop-secret"
fix: patched the Secret to hold the 'api-key' the pod requests
```

**Bug 3 — Empty endpoints:**

```text
$ kubectl get endpoints shop-frontend-svc
shop-frontend-svc   <none>
svc selector app=shopfront  vs  pod label app=shop-frontend
fix: kubectl patch svc shop-frontend-svc -p '{"spec":{"selector":{"app":"shop-frontend"}}}'
```

**Verified fixed:**

```text
$ kubectl get pods | grep shop
shop-frontend-7bc775454d-9z6qz   1/1   Running
shop-frontend-7bc775454d-hbt7p   1/1   Running
$ kubectl get endpoints shop-frontend-svc
shop-frontend-svc   10.244.0.86:80,10.244.0.87:80
```

**Lesson:** bugs hide behind each other — fix the image pull first, and only then does the config error appear. Troubleshoot outward-in: scheduling → image → config → runtime → networking.
