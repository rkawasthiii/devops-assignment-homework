# 05 — DynamoDB & RDS: Database Services

Two managed database services for different data models: **DynamoDB** (NoSQL key-value/doc) vs **RDS** (relational SQL engines).

## DynamoDB — NoSQL

* Fully managed **serverless** NoSQL: no servers, no patching, scales to any throughput
* Single-digit-millisecond latency; on-demand or provisioned capacity billing

### Core concepts

| Concept | Meaning |
| :--- | :--- |
| **NoSQL** | schema-less items, not rows in fixed tables; key-value + document model |
| **Table** | collection of items; no joins — you design tables per access pattern |
| **Item** | one record (like a row); max 400KB |
| **Attribute** | field inside an item (like a column); only keys are mandatory |
| **Partition key (PK)** | mandatory; decides which partition stores the item (hash). Choose high-cardinality to spread load |
| **Sort key (SK)** | optional second key; items share a PK are stored sorted by SK → enables `begins_with`, range queries |

```text
Table: Orders
  PK: userId        SK: orderDate
  item: {userId:"u42", orderDate:"2026-10-01", total:499, status:"shipped"}
```

Query `PK="u42" AND SK begins_with("2026-10")` → all October orders for user 42 — that's the DynamoDB access-pattern mindset. **GSIs** (Global Secondary Indexes) add alternate keys; **DAX** adds caching.

### Use cases
Session stores, user profiles, gaming leaderboards, IoT telemetry, shopping carts, serverless backends (Lambda+DDB), anything needing massive scale + simple lookups — **not** complex relational queries.

## RDS — Relational Database Service

* Managed **relational** databases: AWS handles provisioning, patching, backups, failover — you get a standard engine endpoint and connect normally.

### Supported engines
`MySQL`, `PostgreSQL`, `MariaDB`, `Oracle`, `SQL Server`, and `Amazon Aurora` (AWS's MySQL/PG-compatible engine, ~3-5x faster, replicated storage).

### Core concepts

| Concept | Meaning |
| :--- | :--- |
| **DB instance** | the managed database server (class like `db.t3.micro` picks CPU/RAM) |
| **Security** | private subnets + SG rules; encryption at rest (KMS) + TLS in transit; IAM DB auth possible |
| **Backups** | automated daily backup + transaction logs → **point-in-time restore** (up to 35 days); manual snapshots too |
| **Multi-AZ** | synchronous standby replica in another AZ; **automatic failover** — for availability (not scaling) |
| **Read replicas** | async copies for **read scaling**/offloading; can promote to standalone |

```text
Primary (AZ-a) ──sync──► Standby (AZ-b)    [Multi-AZ: failover]
Primary ──async──► Read Replica(s)         [scale reads, cross-region DR]
```

### Use cases
Web app backends (WordPress, e-commerce), transactional systems, anything needing SQL joins/transactions/ACID, lift-and-shift of on-prem databases.

## DynamoDB vs RDS — quick compare

| | DynamoDB | RDS |
| :--- | :--- | :--- |
| Model | NoSQL key-value/document | Relational (SQL) |
| Schema | none (only keys fixed) | enforced schema |
| Scaling | virtually unlimited, automatic | vertical (bigger instance) + read replicas |
| Queries | PK/SK lookups, GSIs — no joins | full SQL: joins, aggregates, transactions |
| Ops | serverless | managed but you pick instance size |
| Choose when | massive scale, simple lookups | complex queries, existing SQL apps |
