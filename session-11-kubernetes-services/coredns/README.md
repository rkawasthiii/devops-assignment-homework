# CoreDNS — Kubernetes' Internal DNS Server

## What is CoreDNS?

**CoreDNS** is a flexible, plugin-based DNS server (CNCF graduated project) that runs as a Deployment in `kube-system` and serves DNS for the whole cluster. Real output from this cluster:

```bash
$ kubectl -n kube-system get pods -l k8s-app=kube-dns
coredns-7d764666f9-6dqhm   1/1   Running
coredns-7d764666f9-m7g95   1/1   Running

$ kubectl -n kube-system get svc kube-dns
kube-dns   ClusterIP   10.96.0.10   53/UDP,53/TCP,9153/TCP
```

Every pod's `/etc/resolv.conf` points at the `kube-dns` Service IP (`10.96.0.10`):

```text
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10
options ndots:5
```

## Why Kubernetes uses CoreDNS

* **Service discovery is impossible without it** — Pods get random IPs; DNS names are the stable handle.
* It **watches the API server** and auto-creates/updates records the moment a Service or Pod changes — no zone files to edit.
* Plugin architecture: one binary handles cluster DNS, forwarding, caching, metrics, health checks.
* Replaced the older `kube-dns` (dnsmasq+skydns) for being faster, simpler, single-binary.

## How service discovery works

1. `kubectl apply` a Service → API server stores it in etcd.
2. CoreDNS (via the `kubernetes` plugin) watches the API → creates an **A-record** `svc.ns.svc.cluster.local → ClusterIP` instantly.
3. A client pod queries its `nameserver 10.96.0.10` → gets the ClusterIP.
4. Traffic to the ClusterIP is DNAT'd by kube-proxy to a real Pod IP.

| Record type | Created for | Answer |
| :--- | :--- | :--- |
| **A/AAAA** | normal Service | ClusterIP |
| **A** (multi-answer) | headless Service | **each Pod's IP** |
| **SRV** | named ports | port + hostname |
| **CNAME** | ExternalName Service | external DNS name |
| **PTR** | reverse lookups | IP → name |

## How a DNS query is resolved — step by step

```text
Pod runs:  wget http://backend-clusterip
   │
   ▼ /etc/resolv.conf: name < 5 dots → try search list
   query: backend-clusterip.default.svc.cluster.local
   ▼
CoreDNS (10.96.0.10): kubernetes plugin → A-record lookup in its watch-cache
   answer: 10.96.91.106
   ▼
Pod connects to 10.96.91.106:80 → kube-proxy DNAT → pod 10.244.0.4x:80
```

External names (e.g. `api.github.com`) miss the `kubernetes` plugin's zone (`cluster.local`) → `forward` plugin passes them upstream to the node's DNS resolver.

## CoreDNS configuration — the Corefile

```bash
$ kubectl -n kube-system get configmap coredns -o yaml
```

```text
.:53 {
    errors
    health {
       lameduck 5s
    }
    ready
    kubernetes cluster.local in-addr.arpa ip6.arpa {   # serves cluster DNS
       pods insecure
       fallthrough in-addr.arpa ip6.arpa
       ttl 30
    }
    prometheus :9153                                    # metrics endpoint
    forward . /etc/resolv.conf {                        # external → upstream DNS
       max_concurrent 1000
    }
    cache 30 {                                          # answer caching
       disable success cluster.local
       disable denial cluster.local
    }
    loop
    reload
    loadbalance
}
```

## Troubleshooting DNS issues (real workflow)

```bash
# 1. Is CoreDNS running?
kubectl -n kube-system get pods -l k8s-app=kube-dns

# 2. Check CoreDNS logs for errors
kubectl -n kube-system logs deploy/coredns

# 3. Does the pod even ask CoreDNS? Check resolv.conf
kubectl exec <pod> -- cat /etc/resolv.conf        # must show nameserver 10.96.0.10

# 4. Test resolution directly
kubectl exec <pod> -- nslookup kubernetes.default
kubectl exec <pod> -- nslookup <svc>.<ns>.svc.cluster.local

# 5. Distinguish DNS failure from connectivity failure
kubectl exec <pod> -- wget -qO- http://10.96.91.106   # IP works but name fails? → DNS problem
kubectl exec <pod> -- wget -qO- http://bad-name       # name fails → check svc exists + ns

# 6. Check the Service + its Endpoints actually have backends
kubectl get svc,Endpoints <name>
```

Common root causes: CoreDNS pods down/OOM, wrong `nameserver` in resolv.conf (hostNetwork pods skip cluster DNS unless `dnsPolicy: ClusterFirstWithHostNet`), typo'd service name, `ndots` search-list surprises, NetworkPolicy blocking UDP/53.
