# 04 — VPC (Virtual Private Cloud): Networking

## What is VPC?

A VPC is your own **isolated virtual network** inside AWS — you define the IP range, subnets, routing, and security. Every EC2/RDS/etc. lives inside one. Default VPC exists per region; production setups build custom VPCs.

## Core concepts

### CIDR
The VPC's IP range: `10.0.0.0/16` = 65,536 private IPs. Subnets carve it up: `10.0.1.0/24`, `10.0.2.0/24`... (AWS reserves 5 IPs per subnet).

### Subnets
A slice of VPC CIDR in **one Availability Zone**:
* **Public subnet** — route to Internet Gateway → instances get public IPs
* **Private subnet** — no direct internet route; for DBs/internal services
* Best practice: spans 2+ AZs for high availability

### Route tables
Rules deciding where traffic goes. Each subnet associates with a route table:

```text
Public subnet RT:   10.0.0.0/16 → local      (VPC internal)
                    0.0.0.0/0   → igw-xxx    (internet)
Private subnet RT:  10.0.0.0/16 → local
                    0.0.0.0/0   → nat-xxx    (outbound via NAT)
```

### Internet Gateway (IGW)
VPC component enabling **inbound+outbound internet** traffic for public subnets — horizontally scaled, highly available, free.

### NAT Gateway
Lets **private-subnet** instances reach the internet **outbound only** (patches, API calls) while remaining unreachable from outside. Lives in a public subnet with an Elastic IP; billed hourly + data.

```text
Private EC2 → NAT GW → IGW → internet   (out only)
Internet → IGW → ALB → Private EC2      (in via load balancer)
```

### Security Groups vs Network ACLs

| | **Security Group** | **Network ACL** |
| :--- | :--- | :--- |
| Scope | instance/ENI level | **subnet** level |
| Rules | allow only | allow **and** deny |
| State | **stateful** (return traffic auto-allowed) | **stateless** (return must be allowed explicitly) |
| Eval | all rules together | numbered rules, first match wins |
| Use | primary firewall | defense-in-depth edge control |

### Public vs private subnet — summary

| | Public | Private |
| :--- | :--- | :--- |
| Route to IGW | yes | no |
| Gets public IP | yes | no |
| Internet inbound | possible | impossible |
| Internet outbound | direct | via NAT GW |
| Put here | ALB, bastion, NAT GW | app servers, DBs |

### Typical production layout

```text
VPC 10.0.0.0/16
├── public-a  (10.0.1.0/24, AZ-a)  → ALB, NAT GW
├── public-b  (10.0.2.0/24, AZ-b)  → ALB, NAT GW
├── private-a (10.0.11.0/24, AZ-a) → app instances
├── private-b (10.0.12.0/24, AZ-b) → app instances
├── db-a      (10.0.21.0/24, AZ-a) → RDS
└── db-b      (10.0.22.0/24, AZ-b) → RDS standby
```

See [`session19-cloud-terraform`](../../../session19-cloud-terraform/) where this exact layout is written as Terraform code.
