# 01 — Rolling Update Strategy

Kubernetes' **default** strategy: new Pods come up a few at a time (`maxSurge`), and only once they pass readiness are old Pods terminated (`maxUnavailable: 0` → capacity never dips). **Zero downtime.**

```yaml
strategy:
  type: RollingUpdate
  rollingUpdate:
    maxSurge: 1        # at most 1 extra pod above desired count
    maxUnavailable: 0  # never fewer than desired count running
```

## Commands + real output

### Deploy v1

```bash
$ kubectl apply -f deployment-v1.yaml
deployment.apps/app-rolling created

$ kubectl rollout status deployment/app-rolling
deployment "app-rolling" successfully rolled out

$ kubectl get pods -l app=app-rolling --show-labels
NAME                           READY   STATUS    LABELS
app-rolling-54bb479bcb-82x4z   1/1     Running   version=v1
app-rolling-54bb479bcb-85wmt   1/1     Running   version=v1
app-rolling-54bb479bcb-9fxdd   1/1     Running   version=v1
```

### Trigger update to v2

```bash
$ kubectl apply -f deployment-v2.yaml
deployment.apps/app-rolling configured

$ kubectl rollout status deployment/app-rolling
Waiting ... 1 out of 3 new replicas have been updated...
Waiting ... 1 old replicas are pending termination...
deployment "app-rolling" successfully rolled out
```

**Captured mid-rollout** — one v1 pod still terminating while v2 pods already serve:

```text
NAME                           READY   STATUS        LABELS
app-rolling-54bb479bcb-85wmt   1/1     Terminating   version=v1   <-- old being drained
app-rolling-5f5c6548d6-d79xf   1/1     Running       version=v2   <-- new pods live
app-rolling-5f5c6548d6-q5kx8   1/1     Running       version=v2
app-rolling-5f5c6548d6-tz4p5   1/1     Running       version=v2
```

### Rollout history + instant rollback

```bash
$ kubectl rollout history deployment/app-rolling
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

$ kubectl rollout undo deployment/app-rolling
deployment.apps/app-rolling rolled back      # pods flipped back to version=v1
```

**Observed:** Pods were replaced gradually (1-at-a-time surge), the service never went down, and `rollout undo` returned everything to v1 with a single command.
