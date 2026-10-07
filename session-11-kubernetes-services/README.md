# Session 11: Kubernetes Networking & Services — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Cluster: `kind-devops-hw` (K8s v1.35)

Pods get **ephemeral IPs** — a Kubernetes **Service** gives a stable virtual IP + DNS name that load-balances across healthy Pods.

## Task 1: All 5 Service Types — deployed & verified

Setup: [`deployment/backend.yaml`](./deployment/backend.yaml) — 3 nginx replicas + a `curl-test` busybox pod.

```text
$ kubectl get svc
NAME                TYPE           CLUSTER-IP     EXTERNAL-IP      PORT(S)
backend-clusterip   ClusterIP      10.96.91.106   <none>           80/TCP
backend-headless    ClusterIP      None           <none>           80/TCP
backend-lb          LoadBalancer   10.96.122.68   <pending>        80:30397/TCP
backend-nodeport    NodePort       10.96.97.141   <none>           80:30080/TCP
external-api        ExternalName   <none>         api.github.com   <none>
```

### 1. ClusterIP ([`01-clusterip/clusterip.yaml`](./01-clusterip/clusterip.yaml)) — internal-only default

```bash
$ kubectl exec curl-test -- wget -qO- http://backend-clusterip
<title>Welcome to nginx!</title>          # reachable INSIDE the cluster only

$ kubectl exec curl-test -- nslookup backend-clusterip.default.svc.cluster.local
Name:  backend-clusterip.default.svc.cluster.local
Address: 10.96.91.106                     # the Service's virtual IP
```

### 2. NodePort ([`02-nodeport/nodeport.yaml`](./02-nodeport/nodeport.yaml)) — port on every node

```bash
# Service opened port 30080 on the node; reached via node IP 172.20.0.2:
$ kubectl exec curl-test -- wget -qO- http://172.20.0.2:30080
<title>Welcome to nginx!</title>
```

`nodePort: 30080` → any node's IP:30080 forwards into the Service (port 80 → targetPort 80). Port range is `30000–32767`.

### 3. LoadBalancer ([`03-loadbalancer/loadbalancer.yaml`](./03-loadbalancer/loadbalancer.yaml))

```text
backend-lb   LoadBalancer   10.96.122.68   <pending>   80:30397/TCP
```

On kind/minikube there's **no cloud provider**, so `EXTERNAL-IP` stays `<pending>` — on AWS/GCP/Azure a real cloud load balancer with a public IP would be provisioned automatically. (Locally, `kubectl port-forward` or MetalLB fills the gap.)

### 4. ExternalName ([`04-externalname/externalname.yaml`](./04-externalname/externalname.yaml)) — DNS alias to outside

```bash
$ kubectl exec curl-test -- nslookup external-api
external-api.default.svc.cluster.local   canonical name = api.github.com
Name:  api.github.com
Address: 20.207.73.85
```

Pods use the internal name `external-api`; CoreDNS returns a **CNAME** to `api.github.com`. Used to point in-cluster clients at external services (RDS, external APIs) via a stable internal name.

### 5. Headless ([`05-headless/headless.yaml`](./05-headless/headless.yaml)) — `clusterIP: None`

```bash
$ kubectl exec curl-test -- nslookup backend-headless
Name:  backend-headless.default.svc.cluster.local
Address: 10.244.0.39     <-- pod IPs returned DIRECTLY (no VIP!)
Address: 10.244.0.41
Address: 10.244.0.42
```

No virtual IP — DNS answers with **all Pod IPs**. Used for StatefulSets (databases, Kafka) where clients must reach a *specific* Pod: `pod-0.backend-headless.default.svc.cluster.local`.

### `port` vs `targetPort` vs `nodePort`

| Field | Listens where | Who uses it | Example |
| :--- | :--- | :--- | :--- |
| `port` | Service VIP | in-cluster clients | `80` |
| `targetPort` | container | kube-proxy DNAT | `80` |
| `nodePort` | every node's IP | external traffic | `30080` |

## Task 2: Object comparisons

See **[`comparison/README.md`](./comparison/README.md)** — Deployment vs ReplicaSet, Deployment vs DaemonSet vs StatefulSet, ReplicaSet vs Service.

## Task 3: FQDN

See **[`fqdn/README.md`](./fqdn/README.md)** — Kubernetes DNS naming, `<svc>.<ns>.svc.cluster.local`, namespace-based DNS, pod→service communication.

## Task 4: CoreDNS

See **[`coredns/README.md`](./coredns/README.md)** — what CoreDNS is, service discovery, query resolution, config, troubleshooting (with real `/etc/resolv.conf` and `nslookup` output).

## Cleanup

```bash
kubectl delete -f deployment/ -f 01-clusterip/ -f 02-nodeport/ -f 03-loadbalancer/ -f 04-externalname/ -f 05-headless/
```
