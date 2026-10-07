# FQDN — Fully Qualified Domain Names in Kubernetes

## What is an FQDN?

An **FQDN** is the complete, unambiguous domain name of a host — every label from hostname up to the DNS root: `host.subdomain.domain.` (trailing dot = root). `www.google.com.` is an FQDN; `google` alone is just a hostname fragment.

## Kubernetes Service DNS

Every Service in Kubernetes automatically gets a DNS record in **CoreDNS**:

```text
<service-name>.<namespace>.svc.cluster.local
     │             │          └─ cluster domain (default: cluster.local)
     │             └─────────── namespace the Service lives in
     └───────────────────────── the Service's name
```

So a Service `backend-clusterip` in namespace `default` has the FQDN:

```text
backend-clusterip.default.svc.cluster.local   →  10.96.91.106
```

**Real lookup from a pod in this cluster:**

```bash
$ kubectl exec curl-test -- nslookup backend-clusterip.default.svc.cluster.local
Name:  backend-clusterip.default.svc.cluster.local
Address: 10.96.91.106
```

## The naming convention

| Object | FQDN pattern | Example |
| :--- | :--- | :--- |
| Service | `<svc>.<ns>.svc.cluster.local` | `backend-clusterip.default.svc.cluster.local` |
| Pod (headless svc) | `<pod-name>.<svc>.<ns>.svc.cluster.local` | `web-0.backend-headless.default.svc.cluster.local` |
| Pod (by IP) | `<ip-with-dashes>.<ns>.pod.cluster.local` | `10-244-0-41.default.pod.cluster.local` |

## Namespace-based DNS — short names that expand

Pods don't need the FQDN because `/etc/resolv.conf` injects a **search list**:

```text
$ kubectl exec curl-test -- cat /etc/resolv.conf
search default.svc.cluster.local svc.cluster.local cluster.local
nameserver 10.96.0.10          <-- CoreDNS Service IP
options ndots:5
```

| You type (from a pod in `default`) | Resolves to |
| :--- | :--- |
| `backend-clusterip` | `backend-clusterip.default.svc.cluster.local` — same-namespace shortcut |
| `backend-clusterip.production` | `backend-clusterip.production.svc.cluster.local` — cross-namespace |
| `backend-clusterip.default.svc.cluster.local` | full FQDN — always works |

`ndots:5` means names with fewer than 5 dots try the search domains first — which is why the bare name `backend-clusterip` resolves, but a public name like `api.github.com` (2 dots < 5) is also first tried against the search list before going external.

## Pod-to-Service communication

```text
curl-test pod
   │  http://backend-clusterip               (same ns — short name)
   │  http://backend-clusterip.default       (cross-ns would use .<ns>)
   │  http://backend-clusterip.default.svc.cluster.local  (FQDN)
   ▼
CoreDNS (10.96.0.10) ──A-record──► 10.96.91.106 (Service ClusterIP)
   ▼
kube-proxy iptables DNAT ──► one of 10.244.0.39 / .41 / .42 (pod IPs)
```

## Examples of Kubernetes FQDNs

* `kubernetes.default.svc.cluster.local` — the API server's own Service
* `kube-dns.kube-system.svc.cluster.local` — CoreDNS itself
* `web-0.backend-headless.default.svc.cluster.local` — individual Pod via headless Service
* `my-db.staging.svc.cluster.local` — a database Service in `staging` namespace
