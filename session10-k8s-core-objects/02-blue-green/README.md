# 02 — Blue-Green Deployment

Two **complete environments** run side-by-side. The Service selector decides which one gets traffic. Release = change the selector; rollback = change it back. **Instant switch, instant rollback — at the cost of running 2× Pods.**

```text
        ┌── web-blue  (v1, nginx:alpine)     ◄── live
Service ┤
        └── web-green (v2, nginx:1.27-alpine) ◄── staged, idle until flip
```

## Commands + real output

```bash
$ kubectl apply -f blue.yaml       # blue deployment + service pointing at version=blue
$ kubectl apply -f green.yaml      # green deployment (not yet receiving traffic)

$ kubectl get pods --show-labels | grep web-
web-blue-769dbdbfff-4qr55    1/1   Running   version=blue
web-blue-769dbdbfff-t678t    1/1   Running   version=blue
web-green-69c74f4f99-7h6q9   1/1   Running   version=green
web-green-69c74f4f99-z55pw   1/1   Running   version=green
```

### BEFORE the switch — service endpoints point at BLUE pods

```bash
$ kubectl get svc web-service -o jsonpath='{.spec.selector.version}'
blue
$ kubectl get endpoints web-service
web-service   10.244.0.22:80,10.244.0.23:80      # the 2 BLUE pod IPs
```

### THE SWITCH — flip the selector to green

```bash
$ kubectl patch svc web-service -p '{"spec":{"selector":{"version":"green"}}}'
service/web-service patched

$ kubectl get svc web-service -o jsonpath='{.spec.selector.version}'
green
$ kubectl get endpoints web-service
web-service   10.244.0.24:80,10.244.0.25:80      # instantly the 2 GREEN pod IPs
```

**Observed:** within a second, the Service's endpoints changed from blue IPs (`.22`, `.23`) to green IPs (`.24`, `.25`) — 100% of traffic moved at once. Rolling back is just `patch` again to `version: blue`. Old blue pods can be deleted once green proves healthy.
