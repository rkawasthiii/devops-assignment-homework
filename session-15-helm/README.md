# Session 15: Helm — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Helm v4.1.3, cluster `kind-devops-hw`
>
> **Helm** = the package manager for Kubernetes. A **Chart** is a templated bundle of YAML; a **Release** is one installed instance of a chart; `values.yaml` holds the tunables.

---

## Task 1: Helm commands — hands-on (real output)

### `helm create` — scaffold a new chart

```bash
$ helm create myapp
Creating myapp
myapp/
├── Chart.yaml            # chart metadata (name, version, appVersion)
├── values.yaml           # default configuration values
├── templates/            # k8s manifests with Go-template placeholders
│   ├── deployment.yaml   service.yaml   ingress.yaml   hpa.yaml
│   ├── serviceaccount.yaml   _helpers.tpl   NOTES.txt
│   └── tests/test-connection.yaml
└── .helmignore
```

### `helm repo add` / `helm repo list` / `helm search repo`

```bash
$ helm repo add bitnami https://charts.bitnami.com/bitnami
"bitnami" has been added to your repositories

$ helm repo list
NAME      URL
bitnami   https://charts.bitnami.com/bitnami

$ helm search repo nginx --versions
bitnami/nginx   25.2.1   1.31.6   NGINX Open Source...
bitnami/nginx   25.2.0   1.31.6   ...
```

### `helm install` — create a release

```bash
$ helm install myrelease ./myapp --set replicaCount=1 --set image.tag=alpine
NAME: myrelease
STATUS: deployed
REVISION: 1
DESCRIPTION: Install complete
```

### `helm list` / `helm status`

```text
$ helm list
NAME        REVISION  STATUS    CHART         APP VERSION
myrelease   1         deployed  myapp-0.1.0   1.16.0

$ helm status myrelease
NAME: myrelease    STATUS: deployed    REVISION: 1
```

### `helm get` — inspect a release

```bash
$ helm get values myrelease -a      # computed values after --set overrides
image:
  repository: nginx
  tag: latest
replicaCount: 2
service:
  port: 80
  type: ClusterIP
# (helm get manifest <rel> shows the rendered YAML; helm get all <rel> shows everything)
```

### `helm upgrade` / `helm history` / `helm rollback` / `helm uninstall`

See the full workflow in Task 2 below — all four were executed for real.

**Command summary:**

| Command | Purpose |
| :--- | :--- |
| `helm create <name>` | scaffold a chart |
| `helm install <rel> <chart>` | deploy a release |
| `helm list` | list releases in the namespace |
| `helm status <rel>` | release state + notes |
| `helm get values/manifest <rel>` | dump values / rendered YAML |
| `helm upgrade <rel> <chart>` | new revision with changed values |
| `helm history <rel>` | every revision + status |
| `helm rollback <rel> <rev>` | revert to a previous revision |
| `helm uninstall <rel>` | delete release + its resources |
| `helm repo add/list` / `helm search repo` | manage chart repositories / find charts |

---

## Task 2: Complete rollback workflow (real)

```text
Install(rev1) → Upgrade(rev2) → verify → Upgrade(rev3) → verify → Rollback(→rev4=rev1) → verify
```

```bash
# INSTALL — rev 1: nginx:alpine, 1 replica
$ helm install myrelease ./myapp --set replicaCount=1 --set image.tag=alpine
REVISION: 1
$ kubectl get deploy myrelease-myapp -o jsonpath='{.spec.template.spec.containers[0].image}'
nginx:alpine                                         # ✅ verified

# UPGRADE — rev 2: image 1.27-alpine
$ helm upgrade myrelease ./myapp --set image.tag=1.27-alpine
REVISION: 2
$ kubectl get deploy ... -o jsonpath=...image}
nginx:1.27-alpine                                    # ✅ verified

# UPGRADE — rev 3: image latest, 2 replicas
$ helm upgrade myrelease ./myapp --set image.tag=latest --set replicaCount=2
REVISION: 3
$ kubectl get pods -l app.kubernetes.io/instance=myrelease
myrelease-myapp-554f49fddd-92j66   1/1   Running      # ✅ 2 pods verified
myrelease-myapp-554f49fddd-wjl8r   1/1   Running

# ROLLBACK — back to revision 1
$ helm rollback myrelease 1
Rollback was a success! Happy Helming!
$ kubectl get deploy ... -o jsonpath='{.spec.template.spec.containers[0].image} {.spec.replicas}'
nginx:alpine  1                                      # ✅ image AND replicas restored
```

### `helm history` — full audit trail (real output)

```text
REVISION  STATUS      DESCRIPTION
1         superseded  Install complete
2         superseded  Upgrade complete
3         superseded  Upgrade complete
4         deployed    Rollback to 1        <-- rollback itself is a new revision!
```

**Observed:** rollback restores the *values+manifest* of the target revision, but records it as a **new** revision (4), so history is never rewritten — you can even roll back a rollback.

```bash
$ helm uninstall myrelease
release "myrelease" uninstalled
```

---

## Task 3: Mini Project — [`mini-project/notes-chart`](./mini-project/)

A custom chart built with `helm create notes-chart` and installed with tuned values:

```bash
$ helm install notes-release ./notes-chart --set image.tag=alpine --set replicaCount=2
$ kubectl get pods -l app.kubernetes.io/instance=notes-release
notes-release-notes-chart-7f8b44df54-5p7xd   1/1   Running
notes-release-notes-chart-7f8b44df54-xlzq9   1/1   Running
$ helm list
notes-release   deployed   notes-chart-0.1.0   1.16.0
$ helm uninstall notes-release
release "notes-release" uninstalled
```

The chart demonstrates the full Helm workflow end-to-end: `Chart.yaml` metadata, `values.yaml` defaults overridden at install time, templated Deployment/Service/ServiceAccount/HPA/Ingress, NOTES.txt post-install output, and a test-connection pod template.
