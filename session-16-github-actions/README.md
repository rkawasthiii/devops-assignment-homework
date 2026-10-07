# Session 16: CI/CD & GitHub Actions — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)

A complete CI/CD demo project: [`demo/`](./demo/) holds a Node.js app + tests + Dockerfile; the pipeline lives at [`.github/workflows/session16-cicd.yml`](../../.github/workflows/session16-cicd.yml) (repo root so it really runs on push).

## CI vs CD

| | **CI — Continuous Integration** | **CD — Continuous Delivery/Deployment** |
| :--- | :--- | :--- |
| Goal | Every code change is automatically **built + tested** | Every *passing* change is automatically **packaged + released/deployed** |
| In this pipeline | `build-and-test` job (unit tests + artifact), `docker-build` job | `docker-push` job → image pushed to GHCR |

## GitHub Actions anatomy (all demonstrated)

| Concept | Where in the workflow |
| :--- | :--- |
| **Workflow** | the whole `.github/workflows/session16-cicd.yml` file, triggered by `push`/`workflow_dispatch` |
| **Jobs** | `build-and-test`, `docker-build`, `docker-push` — run in parallel unless `needs:` chains them |
| **Steps** | each `uses:`/`run:` block inside a job |
| **Runners** | `runs-on: ubuntu-latest` — GitHub-hosted VM executing the jobs |
| **Secrets** | `${{ secrets.GITHUB_TOKEN }}` — auto-provisioned, used to push to GHCR (DockerHub would use `secrets.DOCKERHUB_TOKEN`) |
| **Artifacts** | `actions/upload-artifact@v4` uploads `demo-app-build` — downloadable from the run page |
| **Build** | `docker build -t cicd-demo:${{ github.sha }}` |
| **Test** | `node --test` + a container **smoke test** (`curl` greps "Hello World") |

```text
push ──► build-and-test ──► docker-build ──► docker-push (GHCR)
           (test+artifact)    (build+smoke)     (publish image)
```

## The app & tests

* [`demo/app/server.js`](./demo/app/server.js) — zero-dependency Node HTTP server; `greeting()` is unit-testable
* [`demo/tests/server.test.js`](./demo/tests/server.test.js) — `node:test` assertions
* [`demo/Dockerfile`](./demo/Dockerfile) — `node:22-bookworm-slim`

```bash
$ node --test
# pass 2   # fail 0        <- verified locally too
```

## Pipeline execution — how to verify

1. Push to `main` → the workflow triggers (path-filtered to `session-16-github-actions/**`).
2. **Actions tab → "Session 16 - CI/CD Demo"** shows all 3 jobs green: tests pass, image builds, smoke test curls the running container, image pushed to `ghcr.io/rkawasthiii/cicd-demo:<sha>`.
3. The `demo-app-build` artifact appears under the run summary.

## Key takeaways

* CI catches breakage **per commit**; CD removes the human step between "green" and "shipped".
* `needs:` builds the job graph — CD only runs if CI passed.
* Secrets never live in code — they're injected via `${{ secrets.* }}`.
* GHCR push needs only the built-in `GITHUB_TOKEN` (`packages: write` permission) — no external credentials.
