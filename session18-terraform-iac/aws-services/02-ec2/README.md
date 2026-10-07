# 02 — EC2 (Elastic Compute Cloud): Compute

## What is EC2?

EC2 provides **resizable virtual machines** (instances) in the AWS cloud — you rent compute capacity by the second, choosing CPU/RAM/OS, instead of buying physical servers. It is the foundational IaaS service most AWS workloads touch.

## Key concepts

### AMI (Amazon Machine Image)
The **template** an instance boots from — OS + pre-installed software + configuration:
* AWS-provided (Amazon Linux, Ubuntu, Windows Server)
* Community/Marketplace AMIs
* Your own golden images (bake with Packer/EC2 Image Builder)

### Instance types
Family-letter + generation + size: `t3.micro` = burstable family `t`, gen 3, micro size.

| Family | Optimized for | Examples |
| :--- | :--- | :--- |
| `t` (burstable) | general/light, spiky load | t3.micro — free tier |
| `m` | balanced general purpose | m7i.large |
| `c` | compute-heavy | c7g.xlarge |
| `r`/`x` | memory-heavy (DBs, caches) | r7i.2xlarge |
| `p`/`g` | GPU / ML | p5, g6 |

### Key pairs
SSH access: AWS holds the **public** key on the instance (`~/.ssh/authorized_keys`), you keep the **private** `.pem`. Lose it → can't SSH (use SSM Session Manager as fallback). Never share or commit the private key.

### Security Groups
**Stateful virtual firewall** attached to instances:
* **Allow rules only** — everything not allowed is denied
* Inbound/outbound evaluated separately; **stateful** — return traffic auto-allowed
* Referenced by other SGs (`allow 3306 from sg-web` — classic web→db pattern)
* vs **NACLs** (subnet-level, stateless, allow+deny rules)

### EBS (Elastic Block Store)
Network-attached **block volumes** persisting independently of the instance:
* `gp3`/`gp2` SSD general, `io2` high-IOPS, `st1`/`sc1` HDD
* Snapshots → S3 for backup/restore/copy across regions
* Survives instance stop/terminate (unless `DeleteOnTermination`)

### Public vs private IP
| | Private IP | Public IP | Elastic IP |
| :--- | :--- | :--- | :--- |
| Scope | inside the VPC | internet-routable | static public you own |
| Lifetime | fixed for instance life | **lost on stop/start** | persists until released |
| Use | internal traffic | ephemeral public access | stable public endpoint |

### Instance lifecycle

```text
pending → running ⇄ stopping/stopped → terminated
              ↑↓ reboot (keeps same host/IP), stop (keeps EBS, new host on start)
```

* **Stop** — EBS data kept, billing for compute stops (EBS still billed)
* **Hibernate** — RAM saved to EBS, fast resume
* **Terminate** — instance deleted; root EBS deleted unless flagged otherwise
* **Spot/Reserved/On-Demand** — purchasing models: Spot ≈ up to 90% off but interruptible; Reserved/Savings Plans for steady workloads

## Common use cases

* Web/app servers behind an ALB + Auto Scaling Group
* Bastion/jump hosts into private subnets
* CI/CD build agents, batch workers (Spot)
* Lift-and-shift migrations of on-prem VMs
