# 01 — IAM (Identity and Access Management): Governance

## What is IAM?

IAM is AWS's **authentication + authorization** system — it controls **who** can do **what** on **which** resources in your AWS account. Every API call is evaluated against IAM before it executes. It is global (not region-scoped) and free.

## Core building blocks

### Users
A named identity for a **person or application** needing long-term access. A user can have console password and/or up to 2 access-key pairs (`AKIA...`). Access keys are for programmatic calls (CLI, SDK, Terraform).

### Groups
A **collection of users** that share permissions. Attach a policy to the group → every member inherits it. Example: `Developers` group gets `PowerUserAccess`; `Auditors` gets `ReadOnlyAccess`. Groups can't be nested and a user can belong to up to 10.

### Roles
An identity with permissions but **no long-term credentials** — it is **assumed temporarily** (STS issues short-lived keys). Used for:
* EC2 instance profiles (app calls AWS APIs without stored keys)
* Cross-account access (`AccountB` assumes a role in `AccountA`)
* Federated login (SSO, SAML, OIDC — e.g. GitHub Actions → AWS via OIDC)

**Rule of thumb:** prefer roles over access keys wherever possible.

### Policies
JSON documents defining **permissions** — attached to users/groups/roles:

```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Action": ["s3:GetObject", "s3:PutObject"],
    "Resource": "arn:aws:s3:::my-bucket/*"
  }]
}
```

* **Managed policies** — AWS-maintained (`AmazonS3ReadOnlyAccess`) or customer-managed reusable policies
* **Inline policies** — embedded directly on one identity
* **Resource policies** — attached to the resource itself (S3 bucket policy, role trust policy)

### Permissions
Evaluation logic: explicit **Deny** beats everything → explicit **Allow** → implicit Deny by default. `Action` (what), `Resource` (on what), `Effect`, `Condition` (when — e.g. only from a specific IP or with MFA).

## Least privilege

Grant **only** the permissions needed, nothing more:

```text
❌  AdministratorAccess on everything "to make it work"
✅  s3:GetObject + s3:PutObject on arn:aws:s3:::app-uploads/* only
```

* Start with zero, add what's needed; use **IAM Access Analyzer** to find unused permissions
* Scope `Resource` to specific ARNs, not `*`
* Use `Condition` for extra safety (require MFA, source IP, tags)

## IAM best practices

1. **Never use the root account** — lock it away, enable MFA on it
2. **MFA everywhere** for humans; SSO/federation instead of IAM users where possible
3. **Roles for workloads**, not shared access keys; rotate any keys that must exist
4. **Least privilege always**; review with Access Analyzer + credential reports
5. **Groups over per-user policies** for manageability
6. **Password policy** + rotate credentials regularly
7. Monitor with **CloudTrail** (every IAM decision is logged)

## Common use cases

* CI/CD: GitHub Actions assumes an IAM **role** via OIDC to deploy — no stored AWS keys
* EC2 app reads S3: attach a **role** to the instance (instance profile)
* Human access: identity-center **federated users** → role per team
* Incident response: a break-glass role with elevated perms + alerting on use
