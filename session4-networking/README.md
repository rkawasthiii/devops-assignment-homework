# Session 4: Networking — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)

---

## Task 1: IP Addressing Notes (from the shared devops-heros repo)

### What is an IP address?
An **IP address** is a unique numeric identifier assigned to every device on a network. IPv4 addresses are **32 bits**, written as 4 octets (`0.0.0.0` – `255.255.255.255`).

### IP Address Classes

| Class | First Octet Range | Default Subnet Mask | Network/Host Bits |
| :--- | :--- | :--- | :--- |
| **A** | 1 – 127 | `255.0.0.0` | 8 network / 24 host |
| **B** | 128 – 191 | `255.255.0.0` | 16 network / 16 host |
| **C** | 192 – 223 | `255.255.255.0` | 24 network / 8 host |
| **D** | 224 – 239 | — (multicast) | — |

### Subnet mask
The **subnet mask** separates the *network part* from the *host part* of an address.

* `120.27.1.0` / `255.0.0.0` → network `120.0.0.0`, broadcast `120.255.255.255`
* `197.23.45.10` / `255.255.255.0` → network `197.23.45.0`, broadcast `197.23.45.255`

**Host calculation (Class A example):**
* network bits = 8 → host bits = 24
* total hosts = 2²⁴, **usable hosts = 2²⁴ − 2** (subtract network + broadcast addresses)

**CIDR notation:** `120.27.1.0/8` means "8 network bits" (mask `255.0.0.0`); `/16` means mask `255.255.0.0`.

### Private IP ranges (RFC 1918)
* `10.0.0.0` – `10.255.255.255` (Class A private)
* `172.16.0.0` – `172.31.255.255` (Class B private)
* `192.168.0.0` – `192.168.255.255` (Class C private)

My machine's IP `100.129.163.194` (see `ipconfig` below) is a **CGNAT** address (carrier-grade NAT range `100.64.0.0/10`) — my ISP puts customers behind shared public IPs.

---

## Task 2: Networking Commands — Real Output + Explanation

> All commands below were executed on my Windows machine (hostname `RADHEY-3773`) and the real output is captured.

### 1. `ipconfig /all` — Show network configuration

```text
Wireless LAN adapter Wi-Fi:

   Connection-specific DNS Suffix  . :
   Description . . . . . . . . . . . : Intel(R) Dual Band Wireless-AC 8265
   Physical Address. . . . . . . . . : 00-28-F8-6B-AD-6E
   DHCP Enabled. . . . . . . . . . . : Yes
   IPv4 Address. . . . . . . . . . . : 100.129.163.194(Preferred)
   Subnet Mask . . . . . . . . . . . : 255.255.240.0
   Default Gateway . . . . . . . . . : 100.129.160.1
```

**What I understood:** Shows my IP address, subnet mask (`255.255.240.0` = `/20`), default gateway, MAC address, and that my IP was assigned by **DHCP**. (Linux equivalent: `ip addr` / `ifconfig`.)

### 2. `ping` — Test connectivity

```text
> ping -n 4 google.com
Reply from 142.250.146.102: bytes=32 time=68ms TTL=113
Reply from 142.250.146.102: bytes=32 time=68ms TTL=113
Reply from 142.250.146.102: bytes=32 time=28ms TTL=113

Ping statistics for 142.250.146.102:
    Packets: Sent = 4, Received = 4, Lost = 0 (0% loss),
Approximate round trip times in milli-seconds:
    Minimum = 28ms, Maximum = 246ms, Average = 102ms
```

**What I understood:** `ping` sends ICMP echo requests to verify a host is reachable and measures round-trip latency. `TTL=113` means the reply passed ~15 routers (started at 128). 0% loss = healthy connection.

### 3. `nslookup` — Query DNS

```text
> nslookup github.com
Server:  wifi.height8tech.com
Address:  100.129.160.1

Non-authoritative answer:
Name:    github.com
Address:  20.207.73.82
```

**What I understood:** `nslookup` asks a DNS server to translate a domain name into an IP address. My DNS server is my gateway (`100.129.160.1`), and `github.com` resolved to `20.207.73.82`. "Non-authoritative" means the answer came from a cached resolver, not GitHub's own DNS server.

### 4. `tracert` — Trace the route packets take

```text
> tracert -d -h 8 -w 1000 8.8.8.8
Tracing route to 8.8.8.8 over a maximum of 8 hops

  1   246 ms     3 ms     4 ms  100.129.160.1
  2    12 ms     3 ms    14 ms  202.131.133.5
  3     6 ms     3 ms     4 ms  115.117.125.189
  4     *        *        *     Request timed out.
  5    31 ms    11 ms    12 ms  115.112.15.114
  6    13 ms    10 ms     9 ms  142.251.227.215
  7    13 ms     9 ms    72 ms  74.125.252.209
  8    10 ms     8 ms    62 ms  8.8.8.8

Trace complete.
```

**What I understood:** `tracert` (Linux: `traceroute`) shows every router ("hop") a packet crosses to reach a destination. Hop 1 is my router, hops 2–5 are ISP hops, hops 6–8 are inside Google's network. The `*` at hop 4 is a router that doesn't reply to ICMP — not necessarily a problem. (Linux: `traceroute`, `mtr`.)

### 5. `netstat -an` — Show open ports & connections

```text
  TCP    0.0.0.0:135            0.0.0.0:0              LISTENING
  TCP    0.0.0.0:445            0.0.0.0:0              LISTENING
  TCP    0.0.0.0:1433           0.0.0.0:0              LISTENING
  TCP    0.0.0.0:5040           0.0.0.0:0              LISTENING
  TCP    0.0.0.0:7680           0.0.0.0:0              LISTENING
  TCP    0.0.0.0:8080           0.0.0.0:0              LISTENING
  TCP    0.0.0.0:8443           0.0.0.0:0              LISTENING
```

**What I understood:** `netstat` lists which TCP/UDP ports are open on my machine. `0.0.0.0:PORT LISTENING` means a service accepts connections on all interfaces. Very useful for checking whether an app actually started on its port. (Linux: `ss -tulpn`.)

### 6. `arp -a` — View the ARP cache

```text
Interface: 100.129.163.194 --- 0x6
  Internet Address      Physical Address      Type
  100.129.160.1         f4-1e-57-3d-a6-d6     dynamic
  100.129.160.19        dc-56-7b-aa-6d-4b     dynamic
  100.129.160.72        9c-c7-d3-2f-0b-9e     dynamic
```

**What I understood:** ARP maps **IP addresses → MAC addresses** on the local network. `100.129.160.1` is my gateway, so its MAC `f4-1e-57-3d-a6-d6` is my router's physical address.

### 7. `curl` — Talk to a web server / API

```text
> curl -s -o /dev/null -w "HTTP %{http_code} - %{url_effective} resolved to %{remote_ip}\n" https://api.github.com
HTTP 200 - https://api.github.com/ resolved to 20.207.73.85
```

**What I understood:** `curl` performs HTTP requests. `HTTP 200` confirms the API is reachable and healthy; I can also see the resolved IP. It's the go-to tool for testing web endpoints from a terminal.

### Command cheat sheet (Windows ↔ Linux)

| Purpose | Windows | Linux |
| :--- | :--- | :--- |
| Show IP config | `ipconfig /all` | `ip addr`, `ifconfig` |
| Connectivity test | `ping -n 4 host` | `ping -c 4 host` |
| DNS lookup | `nslookup` | `dig`, `nslookup`, `host` |
| Trace route | `tracert` | `traceroute`, `mtr` |
| Open ports/connections | `netstat -an` | `ss -tulpn`, `netstat -tulpn` |
| ARP table | `arp -a` | `ip neigh`, `arp -n` |
| HTTP request | `curl` | `curl`, `wget` |
