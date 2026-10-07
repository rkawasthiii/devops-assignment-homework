# Session 13: Kubernetes Storage, HPA & Probes — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Cluster: `kind-devops-hw` (with metrics-server)

---

## Task 1: Kubernetes Volumes — [`01-volumes/`](./01-volumes/)

### emptyDir — shared scratch space, dies with the Pod

Two containers in one Pod sharing an `emptyDir` ([`emptydir-pod.yaml`](./01-volumes/emptydir-pod.yaml)):

```bash
$ kubectl logs -c reader emptydir-demo
data-written-by-writer      # reader saw the file writer created — same volume
```

`emptyDir` is created when the Pod is scheduled, shared by all its containers, and **deleted when the Pod dies**. Use for caches, scratch space, sidecar communication.

### hostPath — mount a directory from the NODE

[`hostpath-pod.yaml`](./01-volumes/hostpath-pod.yaml) mounts `/tmp/hostpath-demo` from the node:

```bash
$ kubectl exec hostpath-demo -- ls -la /node-data/
-rw-r--r--    1 root     root            15 Oct  7 18:36 pod-file.txt

# verified on the actual node filesystem:
$ docker exec devops-hw-control-plane cat /tmp/hostpath-demo/pod-file.txt
hello-from-pod
```

`hostPath` escapes the Pod boundary — data lives on the node itself. Use for node agents (log collectors); dangerous for app data (pods aren't portable + security risk).

### PV / PVC / StorageClass / Dynamic provisioning

* **PersistentVolume (PV)** — a piece of storage in the cluster, provisioned by admin **or** dynamically.
* **PersistentVolumeClaim (PVC)** — a Pod's *request* for storage (size, access mode) — like a Pod is a request for CPU/RAM.
* **StorageClass** — the "menu" of storage types (`standard`, `fast-ssd`, `ebs-gp3`...); defines the *provisioner*.
* **Dynamic provisioning** — create a PVC and the StorageClass's provisioner **creates the matching PV automatically**.

**Real demo** ([`pvc-demo.yaml`](./01-volumes/pvc-demo.yaml)) on kind's built-in `standard` (local-path) StorageClass:

```bash
$ kubectl apply -f pvc-demo.yaml
persistentvolumeclaim/demo-pvc created
pod/pvc-demo created

$ kubectl get pvc
demo-pvc   Bound   pvc-7f2cb1cd-b3bf-4757-b742-a3230ed8ed0e   100Mi   RWO   standard

$ kubectl get pv
pvc-7f2cb1cd-b3bf-4757-b742-a3230ed8ed0e   100Mi   RWO   Delete   Bound   default/demo-pvc   standard
# ^ the PV was auto-created by the provisioner — dynamic provisioning in action

$ kubectl get pod pvc-demo
pvc-demo   1/1   Running
```

**Lifecycle:** `PVC → (provisioner) → PV → Pod mounts it`. Delete the Pod → data persists (`Retain`) or is cleaned (`Delete` reclaim policy).

| Volume type | Data survives Pod death? | Data survives node loss? | Use case |
| :--- | :--- | :--- | :--- |
| `emptyDir` | ❌ | ❌ | scratch/cache |
| `hostPath` | ✅ (on that node) | ❌ | node-level agents |
| `PV/PVC` | ✅ | ✅ (network storage) | databases, stateful apps |

---

## Task 2: HPA hands-on — real autoscaling under load

Deployed [`04-hpa/hpa-app.yaml`](./04-hpa/hpa-app.yaml): nginx (`requests.cpu: 100m`) + Service + HPA (`min 1, max 5, target 20% CPU`) + [`load-generator.yaml`](./04-hpa/load-generator.yaml) hammering the Service in a loop.

```text
=== before load ===
$ kubectl get hpa
hpa-app   Deployment/hpa-app   cpu: 12%/20%   MINPODS:1  MAXPODS:5  REPLICAS: 1

=== during load (load-generator burning 394m CPU) ===
$ kubectl get hpa
hpa-app   Deployment/hpa-app   cpu: 12%/20%   1   5   4        # already scaled 1 → 4

$ kubectl top pods
hpa-app-688c88ff97-8hbwd   15m   5Mi
hpa-app-688c88ff97-c9xln   11m   5Mi
hpa-app-688c88ff97-h88l7   10m   4Mi
hpa-app-688c88ff97-tftfl   15m   5Mi
load-generator             394m  2Mi

$ kubectl get pods | grep hpa-app
hpa-app-688c88ff97-8hbwd   1/1   Running   82s
hpa-app-688c88ff97-c9xln   1/1   Running   82s
hpa-app-688c88ff97-h88l7   1/1   Running   113s    <- original
hpa-app-688c88ff97-tftfl   1/1   Running   82s
```

**HPA event — the scaling decision:**

```text
$ kubectl describe hpa hpa-app
Normal  SuccessfulRescale  horizontal-pod-autoscaler
   New size: 4; reason: cpu resource utilization (percentage of request) above target
```

**After deleting the load generator:**

```text
$ kubectl get hpa
hpa-app   Deployment/hpa-app   cpu: 0%/20%   1   5   4     # will scale back down
```

HPA keeps extra replicas ~5 minutes (scale-down stabilization window) before returning to `minReplicas`.

**Key learnings:** HPA needs **metrics-server** (`kubectl top` proves it's working) and **`resources.requests.cpu`** — the % is measured against requests. Formula: `desiredReplicas = ceil(currentReplicas × currentMetric / target)`.

---

## Probes — [`05-probes/probes-pod.yaml`](./05-probes/probes-pod.yaml)

```bash
$ kubectl describe pod probes-demo | grep -E "Liveness|Readiness|Startup"
    Liveness:   http-get http://:80/ delay=0s period=10s  # dead? → RESTART container
    Readiness:  http-get http://:80/ delay=0s period=5s   # not ready? → remove from Service endpoints
    Startup:    http-get http://:80/ period=2s #failure=30 # slow start? → other probes wait
```

| Probe | Failure consequence | Use for |
| :--- | :--- | :--- |
| **startup** | container restart (others deferred until pass) | slow-booting apps (Java) |
| **readiness** | Pod pulled from Service endpoints (no restart) | "can I serve traffic yet?" |
| **liveness** | container **restart** | deadlocks / hung processes |

---

## Task 3: Mini Project — [`mini-project/mini-project.yaml`](./mini-project/mini-project.yaml)

A production-style **notes-app** combining the whole session in one manifest: `PVC` for durable data + `Deployment` with all 3 probes + resource requests/limits + `Service` + `HPA` (min 2 → max 6 @ 50% CPU).

```bash
kubectl apply -f mini-project/mini-project.yaml
kubectl get pvc,deploy,hpa
```

## Cleanup

```bash
kubectl delete -f 01-volumes/ -f 04-hpa/ -f 05-probes/ -f mini-project/
```
