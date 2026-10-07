# Session 6 & 7: Docker Fundamentals & Docker Images — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)
>
> Every application below was really built with `docker build`, run with `docker run`, and verified live with `curl` — actual output is shown.

---

## Session 6 Task: Hello World Applications in Docker

Six separate folders, each with its own application code + `Dockerfile`:

| Folder | Stack | Internal port | Host port |
| :--- | :--- | :--- | :--- |
| `nodejs-app/` | Node.js (`node:22-bookworm-slim`, built-in `http` module) | 3000 | 3001 |
| `python-app/` | Python (`python:3.13-slim`, built-in `http.server`) | 5000 | 5001 |
| `java-app/` | Java 21 multi-stage (`eclipse-temurin` JDK → JRE) | 8080 | 8084 |
| `Apache-app/` | Apache httpd (`httpd:alpine`) | 80 | 8082 |
| `React-app/` | React+Vite multi-stage (Node build → nginx serve) | 80 | 8083 |
| `nginx-app/` | Nginx (`nginx:alpine`) | 80 | 8081 |

### Builds (all real)

```bash
docker build -t hw-nodejs-app ./nodejs-app
docker build -t hw-python-app ./python-app
docker build -t hw-java-app  ./java-app
docker build -t hw-apache-app ./Apache-app
docker build -t hw-react-app ./React-app
docker build -t hw-nginx-app ./nginx-app
```

React multi-stage build excerpt (real `vite build` output inside Docker):

```text
#12 [build 6/6] RUN npm run build
vite v5.4.21 building for production...
✓ 30 modules transformed.
dist/index.html                  0.34 kB │ gzip:  0.25 kB
dist/assets/index-Drz7O-_z.js  142.69 kB │ gzip: 45.81 kB
✓ built in 58.10s
#14 naming to docker.io/library/hw-react-app:latest DONE
```

### Run + verify each container serves Hello World

```bash
docker run -d --name hw-nodejs -p 3001:3000 hw-nodejs-app
docker run -d --name hw-python -p 5001:5000 hw-python-app
docker run -d --name hw-nginx  -p 8081:80   hw-nginx-app
docker run -d --name hw-apache -p 8082:80   hw-apache-app
docker run -d --name hw-react  -p 8083:80   hw-react-app
docker run -d --name hw-java   -p 8084:8080 hw-java-app
```

**Real `curl` verification:**

```text
$ curl http://localhost:3001
<h1>Hello World from Node.js app running in Docker!</h1>

$ curl http://localhost:5001
<h1>Hello World from Python app running in Docker!</h1>

$ curl http://localhost:8081
<body><h1>Hello World from Nginx running in Docker!</h1></body>

$ curl http://localhost:8082
<body><h1>Hello World from Apache web server running in Docker!</h1></body>

$ curl http://localhost:8084
<h1>Hello World from Java app running in Docker!</h1>

$ curl http://localhost:8083      (React app — served via nginx + JS bundle)
<!DOCTYPE html> ... <div id="root"></div><script ... src="/assets/index-Drz7O-_z.js">
```

**Real `docker ps` output:**

```text
NAMES       PORTS
hw-java     0.0.0.0:8084->8080/tcp
hw-react    0.0.0.0:8083->80/tcp
hw-apache   0.0.0.0:8082->80/tcp
hw-nginx    0.0.0.0:8081->80/tcp
hw-python   0.0.0.0:5001->5000/tcp
hw-nodejs   0.0.0.0:3001->3000/tcp
```

---

## Session 7 Task 1 & 2: Multi-Stage Dockerfile

**Name:** Radhey Kawasthi
**Enrollment Number:** 10242

A multi-stage build uses one stage to *build/install* and a fresh, smaller stage to *run* — the final image ships only what's needed. See [`multi-stage-dockerfile/Dockerfile`](./multi-stage-dockerfile/Dockerfile).

### Steps performed

```bash
$ docker build -t multistage-app ./multi-stage-dockerfile
#8 [builder 4/5] RUN npm install        -> added 68 packages
#11 [production 4/5] RUN npm install --omit=dev  -> added 68 packages
#13 naming to docker.io/library/multistage-app:latest DONE

$ docker run -d --name multistage -p 8080:8080 multistage-app
a205f85f8784fe468b3f24fd0931d921aa939ed3cee175656e99fe179efde48a
```

### Verification — application running on port 8080

```text
$ curl http://localhost:8080
<h1>Hello World from Docker Multi-Stage Build!</h1>
```

### Verification — `docker ps` showing the running container on port 8080

```text
$ docker ps
NAMES        PORTS
multistage   0.0.0.0:8080->8080/tcp, [::]:8080->8080/tcp
```

---

## Session 7 Task 3: Docker Application Deployment

**Deployed 3 different application types via Docker** (all live-verified above):

1. **Node.js** — `hw-nodejs-app` → `http://localhost:3001` → "Hello World from Node.js app running in Docker!"
2. **Python** — `hw-python-app` → `http://localhost:5001` → "Hello World from Python app running in Docker!"
3. **Java** — `hw-java-app` → `http://localhost:8084` → "Hello World from Java app running in Docker!"

(Additionally deployed: Apache httpd, Nginx, and a React single-page app — 6 types total.)

---

## Commands reference used

```bash
docker build -t <name> <path>   # build image from Dockerfile
docker images                   # list images
docker run -d -p host:ctr img   # run detached with port mapping
docker ps                       # running containers
docker logs <ctr>               # container logs
docker stop <ctr> && docker rm <ctr>
docker exec -it <ctr> sh        # shell inside container
```
