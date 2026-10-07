# Session 18: Terraform & Infrastructure as Code — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Terraform v1.16.5

## Task 1: Terraform S3 Demo

👉 [`terraform-s3-demo/`](./terraform-s3-demo/) — creates a secure-by-default S3 bucket.

```text
terraform-s3-demo/
├── provider.tf / variables.tf / main.tf / outputs.tf / terraform.tfvars
└── README.md          # full init→fmt→validate→plan→apply→show→output→destroy workflow
```

**Executed for real:** `terraform init` (downloaded aws provider v5.100.0 → `.terraform.lock.hcl`), `terraform fmt`, `terraform validate` → `Success! The configuration is valid.`
`plan/apply/destroy` need AWS credentials and are documented in the demo README.

## Task 2: AWS Services Research

| Folder | Service | Covers |
| :--- | :--- | :--- |
| [`aws-services/01-iam/`](./aws-services/01-iam/) | **IAM — Governance** | users, groups, roles, policies, least privilege, best practices |
| [`aws-services/02-ec2/`](./aws-services/02-ec2/) | **EC2 — Compute** | AMI, instance types, key pairs, SGs, EBS, IPs, lifecycle |
| [`aws-services/03-s3/`](./aws-services/03-s3/) | **S3 — Storage** | buckets, objects, classes, versioning, lifecycle, encryption, policies |
| [`aws-services/04-vpc/`](./aws-services/04-vpc/) | **VPC — Networking** | CIDR, subnets, route tables, IGW, NAT, SG vs NACL |
| [`aws-services/05-dynamodb-rds/`](./aws-services/05-dynamodb-rds/) | **DynamoDB & RDS** | PK/SK, tables vs items vs attributes; engines, Multi-AZ, read replicas |

## IaC quick notes

* **Declarative**: you describe the *end state* (`resource "aws_s3_bucket" "demo" {...}`), Terraform computes how to get there
* **State file** (`terraform.tfstate`): Terraform's record of what it manages — `plan` diffs desired vs real
* **Workflow**: `init` (providers) → `fmt` (style) → `validate` (syntax) → `plan` (preview) → `apply` (execute) → `show`/`output` (inspect) → `destroy` (cleanup)
