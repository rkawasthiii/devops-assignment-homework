# Pod Lifecycle — Hands-on

A Pod moves through **phases**: `Pending` → `Running` → (`Succeeded` | `Failed`); `Unknown` if the node is unreachable. Inside, each container has its own **state**: `Waiting`, `Running`, or `Terminated`.

```text
Pending ──► (ContainerCreating) ──► Running ──┬──► Succeeded  (all containers exit 0, restartPolicy Never/OnFailure)
        image pull / scheduling               └──► Failed / CrashLoopBackOff (exit ≠ 0)
```

## YAML files applied

* [`pod-running.yaml`](./pod-running.yaml) — nginx, stays `Running`
* [`pod-succeeded.yaml`](./pod-succeeded.yaml) — busybox echoes then exits `0`, `restartPolicy: Never` → `Completed`
* [`pod-crashing.yaml`](./pod-crashing.yaml) — busybox `exit 1` → repeated restarts (`Error` → `CrashLoopBackOff`)

## Real output

```bash
$ kubectl apply -f pod-running.yaml -f pod-succeeded.yaml -f pod-crashing.yaml

# ~16s later (Pending/ContainerCreating already passed for 2 pods):
lifecycle-crashing    0/1   ContainerCreating
lifecycle-running     1/1   Running
lifecycle-succeeded   1/1   Running

# ~40s later:
lifecycle-crashing    0/1   Error                 <-- crashed once, backing off
lifecycle-running     1/1   Running               <-- healthy long-running pod
lifecycle-succeeded   0/1   Completed             <-- job finished, phase Succeeded
```

### `kubectl describe` on the crashing pod — real output

```text
    State:          Terminated
      Reason:       Error
      Exit Code:    1
    Last State:     Terminated
      Reason:       Error
      Exit Code:    1
    Ready:          False
    Restart Count:  1
```

## What I observed

| Pod | Phase reached | Why |
| :--- | :--- | :--- |
| `lifecycle-running` | **Running** | nginx keeps serving; a Service-type workload that never exits |
| `lifecycle-succeeded` | **Completed** | command exited `0`; with `restartPolicy: Never` the Pod stays `Succeeded` (this is how Jobs behave) |
| `lifecycle-crashing` | **Error → CrashLoopBackOff** | `exit 1`; default `restartPolicy: Always` → kubelet restarts it with exponential backoff (10s, 20s, 40s...) |

**Key insight:** `STATUS` column shows container state (`CrashLoopBackOff`, `Completed`), while the Pod *phase* in `kubectl get pod -o yaml` shows `Running`/`Succeeded`/`Failed` — they are different layers.
