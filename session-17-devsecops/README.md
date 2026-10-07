# Session 17: Complete CI/CD & DevSecOps — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)

A full CI/CD + DevSecOps pipeline: [`demo/`](./demo/) contains a Python app + tests + Dockerfile + Kubernetes manifests; the pipeline is [`.github/workflows/session17-devsecops.yml`](../../.github/workflows/session17-devsecops.yml) and **runs for real on every push** touching this folder.

## The flow (exactly as implemented)

```text
Code
  ↓
1. Build + Unit Test          (python -m unittest)
  ↓
2. SAST                       (GitHub CodeQL — static analysis for python)
  ↓
3. SCA                        (Trivy fs scan — vulnerable dependencies)
  ↓
4. Secret Scan                (Gitleaks — credentials in git history)
  ↓
5. Docker Build + Image Scan  (build → Trivy image scan → CRITICAL count gate)
  ↓
6. Push Image                 (GHCR — ghcr.io/rkawasthiii/devsecops-demo:<sha>)
  ↓
7. Deploy to Kubernetes       (manifest validation + kubectl apply)
```

## What each security stage does

| Stage | Tool | Catches | Job in workflow |
| :--- | :--- | :--- | :--- |
| **SAST** (Static Application Security Testing) | `github/codeql-action` | dangerous code patterns in *our* source (injection, unsafe calls) | `sast` |
| **SCA** (Software Composition Analysis) | `aquasecurity/trivy-action` (fs) | known CVEs in *third-party dependencies* (`requirements.txt`) | `sca` |
| **Secret scanning** | `gitleaks/gitleaks-action` | API keys/passwords/tokens committed to the repo | `secret-scan` |
| **Container image scan** | `aquasecurity/trivy-action` (image) | CVEs in OS packages + app deps baked into the image | `docker-build-scan` |
| **Security gate** | Trivy JSON → CRITICAL count | policy checkpoint — pipeline can `exit 1` when findings exceed a threshold | `docker-build-scan` |

## Design notes

* **`needs:` enforces order** — the image is only built after all three security scans pass; it is only pushed after the image scan; deploy runs last.
* **CodeQL** uploads SARIF → findings appear in the repo's **Security → Code scanning** tab (needs `security-events: write`, granted at workflow level).
* **GHCR push** uses the built-in `GITHUB_TOKEN` — no external secrets needed.
* The **deploy** job validates manifests with `kubectl apply --dry-run=client`. A real deployment needs a kubeconfig in `secrets.KUBECONFIG` for the target cluster (EKS/GKE/prod) — documented in the step.

## Files

```text
session-17-devsecops/demo/
├── app/main.py              # hello-world HTTP server (stdlib only)
├── tests/test_main.py       # unittest — verified locally (1 test OK)
├── requirements.txt         # requests==2.32.3 — scanned by SCA
├── Dockerfile               # python:3.13-slim, non-root USER nobody
└── k8s/deployment.yaml      # Deployment + Service (validated in CI)
```

## Verify

Actions tab → **"Session 17 - CI/CD + DevSecOps"** → 7 jobs in sequence, each green. Image lands at `ghcr.io/rkawasthiii/devsecops-demo`; CodeQL findings (if any) appear under the Security tab.
