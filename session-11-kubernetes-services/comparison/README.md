# Task 2: Kubernetes Object Comparison

## Deployment vs ReplicaSet

| | **ReplicaSet** | **Deployment** |
| :--- | :--- | :--- |
| **Purpose** | Guarantee that exactly *N* identical Pods are running at all times | Manage ReplicaSets + provide **declarative updates** (rollouts) |
| **Pod management** | Creates/deletes Pods to match `replicas`; replaces crashed Pods | Delegates to a ReplicaSet; a new template version → new RS |
| **Scaling** | `kubectl scale rs` (rarely done directly) | `kubectl scale deploy` → scales the active RS |
| **Rolling updates** | ❌ Cannot — only replaces Pods with the same spec | ✅ Creates new RS, scales it up while old RS scales down; rollback via `rollout undo` |
| **Relationship** | The worker — owned by the Deployment | The manager — owns a stack of ReplicaSets (one per revision) |

```text
Deployment ──owns──► ReplicaSet (rev 2, active) ──► Pods v2
                  └─ ReplicaSet (rev 1, scaled 0) ──► (kept for rollback)
```

**Rule:** never create a bare ReplicaSet in practice — create a Deployment and let it manage the RS.

## Deployment vs DaemonSet vs StatefulSet

| | **Deployment** | **DaemonSet** | **StatefulSet** |
| :--- | :--- | :--- | :--- |
| **Use case** | Stateless apps (web APIs, frontends) | Node-level agents — **one pod per node** (log collectors, kube-proxy, monitoring) | Stateful apps needing **stable identity** (DBs, Kafka, Zookeeper) |
| **Pod creation** | Random names + can run anywhere | Exactly 1 per node; new node → auto-scheduled | Ordered names `pod-0, pod-1...` created in sequence |
| **Scaling** | Freely scale replicas up/down | "Scales" with cluster size | Scales in strict order (0→1→2 up, reverse down) |
| **Networking** | Pods interchangeable behind Service | Node-local | **Stable DNS** per pod via headless Service (`pod-0.svc`) |
| **Storage** | Shared/ephemeral typical | Usually none | Each Pod gets its **own PVC** that survives restarts (`volumeClaimTemplates`) |
| **Example** | `nginx` frontend | `fluentd`, `kube-proxy`, `kindnet` | `mysql`, `kafka`, `elasticsearch` |

## ReplicaSet vs Service

| | **ReplicaSet** | **Service** |
| :--- | :--- | :--- |
| **Responsibility** | *Compute*: keep N Pods alive | *Networking*: stable VIP + DNS + load-balancing to Pods |
| **Knows Pods by** | `selector` matching pod labels | `selector` matching pod labels |
| **Why the Service is needed** | Pods are ephemeral — IPs change on every restart/scale | Clients need **one address** that never changes |
| **How traffic reaches Pods** | (not its job) | CoreDNS name → ClusterIP → `kubectl get endpoints` → kube-proxy iptables/IPVS DNAT → a ready Pod |

```text
ReplicaSet:  "keep 3 backend Pods alive"         (the WHAT / count)
Service:     "answer backend:80 → pod IPs list"  (the HOW to reach them)
```

A ReplicaSet without a Service = running Pods nobody can reliably reach.
A Service without a ReplicaSet = a stable name pointing at an empty/managed-by-hand set of Pods (`endpoints <none>`).
