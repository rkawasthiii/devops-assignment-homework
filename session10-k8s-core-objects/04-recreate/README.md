# 04 — Recreate Strategy

**Kill every old Pod first, then create the new ones.** Simple, but produces a downtime window. Used when old and new versions can't coexist (e.g. incompatible DB schema, single-connection apps).

```yaml
strategy:
  type: Recreate
```

## Commands + real output

```bash
$ kubectl apply -f deployment.yaml        # v1 up, 3 replicas
$ kubectl get pods -l app=app-recreate
app-recreate-5cbbbb769-hvbw7   1/1   Running
app-recreate-5cbbbb769-m5ljx   1/1   Running
app-recreate-5cbbbb769-xmgpj   1/1   Running

$ kubectl set image deployment/app-recreate web=nginx:1.27-alpine
deployment.apps/app-recreate image updated
```

### Deployment events — the smoking gun

```text
$ kubectl describe deployment app-recreate
Events:
  Normal  ScalingReplicaSet  Scaled up   replica set app-recreate-5cbbbb769 from 0 to 3   (v1 start)
  Normal  ScalingReplicaSet  Scaled down replica set app-recreate-5cbbbb769 from 3 to 0   (ALL v1 killed FIRST)
  Normal  ScalingReplicaSet  Scaled up   replica set app-recreate-59844f958 from 0 to 3   (then v2 created)
```

Compare with RollingUpdate, where the new ReplicaSet scales up **while** the old one still has Pods. Here the old RS went `3 → 0` **before** the new RS went `0 → 3` — a real (if short) outage window in between.

```bash
$ kubectl rollout status deployment/app-recreate
deployment "app-recreate" successfully rolled out
```

**Observed:** total termination of the old version before any new Pod started — clean cutover, brief downtime, zero version mixing.
