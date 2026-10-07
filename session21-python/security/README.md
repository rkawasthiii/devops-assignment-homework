# Security — Taskboard Final Project

DevSecOps controls applied in this project, enforced in the CI pipeline ([`../.github/workflows/final-pipeline.yml`](../.github/workflows/final-pipeline.yml)):

| Control | Tool | Stage |
| :--- | :--- | :--- |
| **SAST** | GitHub CodeQL (python) | `sast` — static analysis of `application/` |
| **SCA** | Trivy fs scan | `sca` — CVEs in `requirements.txt` deps |
| **Secret scanning** | Gitleaks | `secret-scan` — credentials in history |
| **Container image scan** | Trivy image | `image-scan` — OS + app CVEs in the built image |
| **Security gate** | CRITICAL count check | fails the pipeline if criticals exceed threshold |
| **Non-root container** | `USER nobody` in `docker/Dockerfile` | runtime hardening |
| **K8s hardening** | `resources.limits`, probes, `block_public_access` S3 | `kubernetes/manifests/` |

## Policy notes

* Secrets in manifests are **demo placeholders** — production uses external secret managers (AWS Secrets Manager / Vault / External Secrets Operator).
* Trivy reports upload as artifacts for review; the gate step counts CRITICAL findings.
* `.gitignore` excludes `*.tfstate`, `.terraform/` so credentials/state never reach Git.
