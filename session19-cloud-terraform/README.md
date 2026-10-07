# Session 19: Cloud & Terraform in Action — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242) | Terraform v1.16.5, AWS provider v5.100.0

An end-to-end cloud infrastructure project in Terraform: **VPC → Subnet → IGW → Route Table → Security Group → EC2 (web server) → S3**.

## Architecture

```text
                            ┌───────── AWS Region: ap-south-1 ─────────┐
                            │                                          │
  Internet                  │   VPC 10.0.0.0/16                        │
     │                      │   ┌──────────────────────────────────┐   │
     ▼                      │   │ Public Subnet 10.0.1.0/24  (AZ-a)│   │
┌─────────┐   0.0.0.0/0    │   │                                  │   │
│   IGW   │◄── Route Table │   │  ┌────────────┐   ┌───────────┐  │   │
└─────────┘◄────────────── │   │  │ EC2 t3.micro│──►│ Web SG    │  │   │
                            │   │  │ (httpd)    │   │ 80,22 in  │  │   │
                            │   │  └────────────┘   └───────────┘  │   │
                            │   └──────────────────────────────────┘   │
                            │                                          │
                            │   S3 bucket (versioned access-blocked)   │
                            └──────────────────────────────────────────┘
```

## Files

| File | Role |
| :--- | :--- |
| `main.tf` | provider + all resources (VPC, IGW, subnet, RT, SG, EC2, S3) |
| `variables.tf` | `aws_region`, `project`, `vpc_cidr`, `instance_type`, `bucket_name`, `ssh_cidr` |
| `outputs.tf` | `vpc_id`, `instance_public_ip`, `website_url`, `bucket_name` |
| `terraform.tfvars` | concrete values |

## Terraform concepts demonstrated

| Concept | Where |
| :--- | :--- |
| **Providers** | `provider "aws" { region = var.aws_region }` + `required_providers` pinning `~> 5.0` |
| **Variables** | everything parameterized — `terraform.tfvars` overrides defaults |
| **Resources** | `aws_vpc`, `aws_subnet`, `aws_security_group`, `aws_instance`, `aws_s3_bucket` |
| **Outputs** | `output "website_url"` → prints the live URL after apply |
| **Dependencies** | implicit: `subnet_id = aws_subnet.public.id` — TF builds a graph and orders creation (VPC → IGW/subnet → RT assoc/SG → EC2); explicit `depends_on` also exists |
| **Data source** | `data "aws_ami"` looks up the latest Amazon Linux AMI at plan time |
| **State** | `terraform.tfstate` records real resource IDs; `plan` = state vs desired |

## Executed

```text
$ terraform init
- Installing hashicorp/aws v5.100.0... Installed (signed by HashiCorp)
Terraform has been successfully initialized!

$ terraform fmt -recursive      # canonicalized main.tf
$ terraform validate
Success! The configuration is valid.
```

`plan` / `apply` / `destroy` require AWS credentials (`aws configure` or `AWS_ACCESS_KEY_ID`/`AWS_SECRET_ACCESS_KEY` env vars). Once configured:

```bash
terraform plan            # preview: "10 to add"
terraform apply           # provisions everything, prints website_url
# open http://<instance_public_ip> -> "Hello from Terraform-provisioned EC2 - Radhey 10242"
terraform destroy         # tears every resource down cleanly
```

## The workflow commands

```bash
terraform init      # download providers, initialize backend
terraform fmt       # format to canonical style
terraform validate  # syntax/consistency check
terraform plan      # dry-run diff: desired vs state vs reality
terraform apply     # create/update real resources
terraform show      # dump current state
terraform output    # print outputs (public IP, URL, bucket name)
terraform destroy   # delete everything it created
```
