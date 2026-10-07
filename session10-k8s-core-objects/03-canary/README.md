# 03 — Canary Deployment

Run the **stable** version (3 Pods) plus **one small canary** Pod of the new version. The Service selects `app: web-canary-demo` which matches **both**, so ~25% of requests (1 of 4 Pods) hit the canary. If it looks healthy, scale it up gradually.

```text
Service (selector: app=web-canary-demo)
  ├─ web-stable  x3  (v1) ─── ~75% of traffic
  └─ web-canary  x1  (v2) ─── ~25% of traffic
```

## Commands + real output

```bash
$ kubectl apply -f canary.yaml
deployment.apps/web-stable created
deployment.apps/web-canary created
service/web-canary-service created

$ kubectl get pods --show-labels | grep web-
web-canary-77c8f5c664-7j6zh  1/1  Running  track=canary,version=v2
web-stable-6bff8d555-6zctq   1/1  Running  track=stable,version=v1
web-stable-6bff8d555-9dst9   1/1  Running  track=stable,version=v1
web-stable-6bff8d555-sg9nv   1/1  Running  track=stable,version=v1
```

### Both versions are inside ONE Service's endpoints

```bash
$ kubectl get endpoints web-canary-service
web-canary-service   10.244.0.26:80,10.244.0.27:80,10.244.0.28:80 + 1 more...
#                  └──────────── 3 stable pod IPs ─────────────┘  └ canary ─┘
```

**Observed:** the Service load-balances across all 4 Pods weighted equally → the single canary Pod receives roughly 25% of traffic. To promote the release: scale `web-canary` up and `web-stable` down progressively. To abort: `kubectl delete deployment web-canary`.

> **Note:** exact percentage-based splitting (e.g. 90/10) needs an Ingress/service-mesh layer (NGINX Ingress `canary-weight`, Istio); plain k8s gives pod-count-weighted canary, demonstrated here.
