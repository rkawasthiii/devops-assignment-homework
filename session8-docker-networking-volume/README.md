# Session 8: Docker Networking & Volumes — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)
>
> All commands executed for real; actual output shown.

---

## Task 1: Docker Container Networking

**Topology:** 3 user-defined bridge networks. `frontend` + `backend` are nginx; `database` is MySQL 8. The **backend** container sits on **2 networks**, giving it access to both tiers while the frontend can never reach the database directly.

```text
                 frontend-net          backend-net           db-net
              ┌───────────────┐    ┌────────────────┐   ┌──────────┐
  frontend ──►│  frontend     │    │                │   │          │
              │  backend  ◄───┼────┼─► backend       │   │          │
              │     (nginx)   │    │   database ◄────┼───┼─►database│
              └───────────────┘    │    (mysql:8)    │   │  (mysql) │
                                   └────────────────┘   └──────────┘
```

### Commands + real output

```bash
$ docker network create frontend-net
$ docker network create backend-net
$ docker network create db-net
$ docker network ls
b535dcac1f34   backend-net    bridge    local
75969ad604b8   db-net         bridge    local
910b54033a46   frontend-net   bridge    local

$ docker run -d --name frontend --network frontend-net nginx:alpine
$ docker run -d --name backend  --network frontend-net nginx:alpine
$ docker run -d --name database --network backend-net \
      -e MYSQL_ROOT_PASSWORD=rootpass -e MYSQL_DATABASE=appdb mysql:8.0

# backend joins a SECOND network:
$ docker network connect backend-net backend
$ docker network connect db-net database
```

### Connectivity checks (real output)

```text
# ✅ frontend -> backend  (share frontend-net)
$ docker exec frontend wget -qO- http://backend
... <title>Welcome to nginx!</title> ...

# ✅ backend -> database:3306  (share backend-net)
$ docker exec backend nc -zw3 database 3306 && echo reachable
OK: database:3306 reachable from backend

# ❌ frontend -> database  (NO shared network — isolated)
$ docker exec frontend wget -qO- http://database
wget: bad address 'database'
```

**What I learned:** containers on the same user-defined bridge resolve each other **by name** via Docker's embedded DNS (`backend` → 172.x, `database` → 172.22.0.2). Containers on *different* networks can't even resolve the name — that's real network isolation, the basis of microservice tiering.

---

## Task 2: Host Network

```bash
$ docker run -d --name apache-host --network host httpd:alpine

# Apache listens on port 80 inside the host's network namespace:
$ docker exec apache-host netstat -tln | grep ":80 "
tcp        0      0 :::80         :::*        LISTEN

# Accessed directly on port 80 (no -p flag needed!):
$ docker exec apache-host wget -qO- localhost:80
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" ...>
<html>...
```

**What I learned:** with `--network host` the container has **no port mapping** (`-p` is ignored) — it binds ports straight onto the host interface. Note: on Docker Desktop (Windows/Mac) the "host" is Docker's internal Linux VM, so `localhost` is reachable *inside the VM* rather than on Windows — on native Linux the Apache page is directly at `http://localhost:80`.

---

## Task 3: Bind Mount

```bash
$ mkdir bindmount-site
$ echo "<h1>Hello students</h1>" > bindmount-site/index.html
$ docker run -d --name nginx-bind -p 8085:80 \
      -v /path/to/bindmount-site:/usr/share/nginx/html nginx:alpine
```

### Real output

```text
=== before edit ===
$ curl http://localhost:8085
<h1>Hello students</h1>

# edited index.html on the HOST (container NOT restarted):

=== after edit ===
$ curl http://localhost:8085
<h1>Hello students - UPDATED without restart!</h1>
```

**What I learned:** a bind mount maps a host folder directly into the container — file edits on the host are **instantly visible** inside the container. Perfect for dev workflows; the mounted [`bindmount-site/`](./bindmount-site/) folder is in this repo.

---

## Task 4: Overlay Network (research)

* **What it is:** a network that spans **multiple Docker hosts**, making containers on different machines behave as if on one LAN. Built on **VXLAN** (encapsulates L2 frames in UDP/4789) on top of Docker **Swarm** (`docker swarm init`).
* **How it works:** the Swarm control plane distributes network state (endpoints, IPs) to every node via gossip (Serf). Each node gets a VXLAN tunnel endpoint; container traffic between hosts is encapsulated at the source VTEP and decapsulated at the destination.
* **Use cases:** Swarm services spanning nodes (`docker service create --network myoverlay`), microservices where a frontend on host A talks to a database on host B by DNS name, encrypted cross-host traffic (`--opt encrypted` uses IPsec).
* **vs bridge:** `bridge` = single host only; `overlay` = multi-host. In practice, **Kubernetes** (kind/minikube) provides the same concept through CNI plugins (kindnet, Calico, Flannel) — which is what we use in Sessions 9+.

```bash
# how you'd create one on a Swarm:
docker swarm init
docker network create -d overlay my-overlay
docker service create --name web --network my-overlay nginx
```

---

## Cleanup commands used

```bash
docker rm -f frontend backend database apache-host nginx-bind
docker network rm frontend-net backend-net db-net
```
