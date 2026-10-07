# Session 9: Kubernetes Fundamentals — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)
>
> Cluster: local **kind** (`kind-devops-hw`, Kubernetes v1.35) — a CNCF tool that runs a real Kubernetes cluster inside Docker, equivalent to Minikube for local learning. All commands executed for real.

---

## Task 1 & 2: Install cluster + verify status

```bash
$ kind create cluster --name devops-hw
Creating cluster "devops-hw" ...
 ✓ Starting control-plane 🕹️  ✓ Installing CNI 🔌  ✓ Installing StorageClass 💾
Set kubectl context to "kind-devops-hw"

$ kubectl cluster-info
Kubernetes control plane is running at https://127.0.0.1:55698
CoreDNS is running at https://127.0.0.1:55698/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

$ kubectl get nodes -o wide
NAME                      STATUS   ROLES           AGE     VERSION   INTERNAL-IP   CONTAINER-RUNTIME
devops-hw-control-plane   Ready    control-plane   3m45s   v1.35.0   172.20.0.2    containerd://2.2.0

$ kubectl get componentstatuses
NAME                 STATUS    MESSAGE   ERROR
scheduler            Healthy   ok
controller-manager   Healthy   ok
etcd-0               Healthy   ok
```

Control-plane components all running (real output of `kubectl get pods -A`):

```text
kube-system   etcd-devops-hw-control-plane                      1/1  Running
kube-system   kube-apiserver-devops-hw-control-plane            1/1  Running
kube-system   kube-controller-manager-devops-hw-control-plane   1/1  Running
kube-system   kube-scheduler-devops-hw-control-plane            1/1  Running
kube-system   coredns-7d764666f9-xxxxx                          1/1  Running (x2)
kube-system   kube-proxy-9rwbc                                  1/1  Running
kube-system   kindnet-6wbnx                                     1/1  Running
```

---

## Task 3: Kubernetes Architecture — short notes

```text
┌───────────────────────── CONTROL PLANE ─────────────────────────┐
│  kube-apiserver   – front door; every kubectl call goes here    │
│  etcd             – key-value store = the cluster's source truth│
│  kube-scheduler   – decides WHICH node a new Pod runs on        │
│  controller-mgr   – loops that keep desired state = real state  │
│                     (Deployment, ReplicaSet, Node controllers)  │
└─────────────────────────────────────────────────────────────────┘
┌───────────────────────── WORKER NODES ──────────────────────────┐
│  kubelet          – agent on each node; talks to containerd     │
│  kube-proxy       – programs iptables rules for Services        │
│  container runtime– containerd / CRI-O runs the actual images   │
└─────────────────────────────────────────────────────────────────┘
```

*Flow:* `kubectl apply` → apiserver validates → stores in etcd → scheduler picks a node → kubelet pulls image + starts container → controllers keep watching to heal drift.

### Basic objects & commands learned

| Object | What it is | Command |
| :--- | :--- | :--- |
| **Pod** | smallest unit; 1+ containers sharing net/storage | `kubectl get pods` |
| **Deployment** | manages ReplicaSets → desired count of Pods | `kubectl get deploy` |
| **ReplicaSet** | keeps N identical Pods alive | `kubectl get rs` |
| **Service** | stable IP/DNS in front of Pods | `kubectl get svc` |
| **Namespace** | virtual cluster partition | `kubectl get ns` |

---

## Task 4 & 5: Kubernetes Basics tutorial — hands-on

### Step 1 — create a deployment

```bash
$ kubectl create deployment kubernetes-bootcamp --image=nginx:alpine --port=80 --replicas=1
deployment.apps/kubernetes-bootcamp created

$ kubectl get pods -o wide
NAME                                  READY   STATUS    IP          NODE
kubernetes-bootcamp-67569b46c-x2wnk   1/1     Running   10.244.0.5  devops-hw-control-plane
```

### Step 2 — expose it as a Service

```bash
$ kubectl expose deployment kubernetes-bootcamp --type=NodePort --port=80
service/kubernetes-bootcamp exposed

$ kubectl get svc
NAME                  TYPE       CLUSTER-IP     EXTERNAL-IP   PORT(S)
kubernetes-bootcamp   NodePort   10.96.34.147   <none>        80:31852/TCP
```

### Step 3 — scale to 4 replicas

```bash
$ kubectl scale deployment kubernetes-bootcamp --replicas=4
deployment.apps/kubernetes-bootcamp scaled

$ kubectl get pods -o wide
NAME                                  READY   STATUS    IP
kubernetes-bootcamp-67569b46c-6f2qt   1/1     Running   10.244.0.6
kubernetes-bootcamp-67569b46c-lj7cj   1/1     Running   10.244.0.8
kubernetes-bootcamp-67569b46c-x2wnk   1/1     Running   10.244.0.5
kubernetes-bootcamp-67569b46c-x7zsc   1/1     Running   10.244.0.7

$ kubectl get deploy
NAME                  READY   UP-TO-DATE   AVAILABLE
kubernetes-bootcamp   4/4     4            4
```

### Step 4 — rolling update to a new image

```bash
$ kubectl set image deployment/kubernetes-bootcamp nginx=nginx:1.27-alpine
deployment.apps/kubernetes-bootcamp image updated

$ kubectl rollout status deployment/kubernetes-bootcamp
Waiting ... 1 old replicas are pending termination...
deployment "kubernetes-bootcamp" successfully rolled out

$ kubectl rollout history deployment/kubernetes-bootcamp
REVISION  CHANGE-CAUSE
1         <none>
2         <none>

$ kubectl describe pods | grep "Image:"
Image:  nginx:1.27-alpine   (x4 — all Pods on the new version)
```

### Cleanup

```bash
$ kubectl delete deployment kubernetes-bootcamp
$ kubectl delete svc kubernetes-bootcamp
```

**What I learned:** a Deployment declaratively manages Pods — `scale` changes the replica count and the ReplicaSet controller converges reality to it; `set image` triggers a rolling update where new Pods come up before old ones die; `rollout history/undo` gives built-in revision control.

---

## Resources

* [Kubernetes Basics Tutorial](https://kubernetes.io/docs/tutorials/kubernetes-basics/)
* [Minikube Installation Guide](https://minikube.sigs.k8s.io/docs/start/) (kind used here as equivalent)
* [Kubernetes Architecture](https://kubernetes.io/docs/concepts/architecture/)
* [Kubernetes GitHub Repository](https://github.com/Nency-Ravaliya/Kubernetes)
