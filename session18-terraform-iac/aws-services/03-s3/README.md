# 03 — S3 (Simple Storage Service): Storage

## What is S3?

S3 is AWS's **object storage** — effectively unlimited, 99.999999999% (11 nines) durable, accessed over HTTP/API. You store **objects** (files) in **buckets** and pay for storage + requests + transfer.

## Core concepts

### Buckets
* Top-level container; name must be **globally unique** across ALL AWS accounts (`radhey-10242-terraform-s3-demo`)
* Created in a specific **region**
* Flat namespace — "folders" are just key prefixes (`logs/2026/app.log`)

### Objects
`key (name) + data + metadata + versionId`. Max 5TB per object; multipart upload for >100MB recommended.

### Storage classes

| Class | Use | Retrieval |
| :--- | :--- | :--- |
| **S3 Standard** | hot data, frequent access | instant |
| **Standard-IA** | infrequent access, still fast | instant + retrieval fee |
| **One Zone-IA** | cheaper, single AZ (reproducible data) | instant + fee |
| **Intelligent-Tiering** | auto-moves objects between tiers by access | instant |
| **Glacier Instant / Flexible / Deep Archive** | archival | ms → hours |
| **Lifecycle policies** move objects automatically (e.g. → IA after 30d, Glacier after 90d, delete after 365d) | | |

### Versioning
Keeps **every version** of an object — overwrite/delete creates a new version or delete-marker instead of losing data. Protects against accidents + ransomware; costs storage for each version (pair with lifecycle rules to expire old versions).

### Lifecycle policies
Rules auto-transitioning or expiring objects: `transition to GLACIER after 90 days`, `expire noncurrent versions after 30 days`, `abort incomplete multipart uploads after 7 days`. Essential for cost control.

### Encryption
* **SSE-S3 (AES256)** — AWS-managed keys, default now on all new objects
* **SSE-KMS** — your/AMS-managed keys with audit trail in CloudTrail
* **SSE-C** — customer-provided keys
* Client-side encryption possible before upload

### Bucket policies
Resource-based JSON policies attached to the bucket — e.g. allow CloudFront to read, enforce TLS-only (`aws:SecureTransport`), deny public access. Complement IAM; combined with **Block Public Access** (4 switches blocking ACLs/policies that expose the bucket — keep all ON, as in our terraform demo).

## Common use cases

* Static website hosting + CloudFront CDN
* Data lakes / analytics storage (Athena queries S3 directly)
* Backups, archives, disaster recovery (cross-region replication)
* App assets/uploads, logs, CI artifacts, Terraform state (`backend "s3"`)

## Quick terraform link

Our [`terraform-s3-demo`](../../terraform-s3-demo/) creates exactly this: bucket + versioning + SSE-S3 + `aws_s3_bucket_public_access_block` all-true — the secure-by-default baseline.
