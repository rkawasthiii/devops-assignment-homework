# Session 1 & 2: Linux Fundamentals — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)
>
> Commands were executed on Ubuntu 22.04 (Linux); real output is shown.

---

## Task 1: Soft Link vs Hard Link

### The difference (interview answer)

| | **Hard link** | **Soft link (symbolic link)** |
| :--- | :--- | :--- |
| What it is | Another *name* pointing to the **same inode** (same data) | A special file that stores a **path** to another file |
| Inode | **Shares** the original file's inode | Has its **own** inode |
| If original is deleted | Link **still works** (data survives until all links removed) | Link **breaks** (dangling → "No such file or directory") |
| Across filesystems | ❌ No (inodes are per-filesystem) | ✅ Yes |
| Link to a directory | ❌ No (for normal users) | ✅ Yes |
| Command | `ln target linkname` | `ln -s target linkname` |

### Hands-on — real output

```bash
$ echo "hello devops" > original.txt
$ ln  original.txt hardlink.txt      # hard link
$ ln -s original.txt softlink.txt    # soft link

$ ls -li
1652417 -rw-r--r-- 2 root root 13 Oct  7 18:03 hardlink.txt
1652417 -rw-r--r-- 2 root root 13 Oct  7 18:03 original.txt   <-- SAME inode 1652417
1652425 lrwxrwxrwx 1 root root 12 Oct  7 18:03 softlink.txt -> original.txt  <-- different inode, 'l' type

$ cat hardlink.txt
hello devops
$ cat softlink.txt
hello devops

$ rm original.txt              # delete the original

$ cat hardlink.txt
hello devops                   # ✅ still works — inode/data alive

$ cat softlink.txt
cat: softlink.txt: No such file or directory   # ❌ dangling link — path is gone
```

**Observed:** `hardlink.txt` and `original.txt` shared inode `1652417` — the data lived on after the original name was deleted. `softlink.txt` only stored a *path*, so it broke immediately.

---

## Task 2: `adduser` vs `useradd`

### The difference

| | `useradd` | `adduser` |
| :--- | :--- | :--- |
| Type | Low-level binary (compiled) | Friendly Perl script that **wraps `useradd`** |
| Home directory | ❌ Not created unless `-m` given | ✅ Created automatically, `/etc/skel` copied in |
| Password/shell prompts | ❌ No — bare entry only | ✅ Interactive setup |
| Portability | Same on all distros | Debian/Ubuntu family (others differ) |
| **Preferred on Ubuntu?** | Scripts/automation | **Yes — for humans.** It does the "right thing" by default |

### Hands-on — real output

```bash
$ useradd testuser1
$ grep testuser1 /etc/passwd
testuser1:x:1000:1000::/home/testuser1:/bin/sh
$ ls -ld /home/testuser1
ls: cannot access '/home/testuser1': No such file or directory   # ❌ no home dir, /bin/sh shell

$ adduser --disabled-password --gecos "Test User" testuser2
Adding user `testuser2' ...
Adding new group `testuser2' (1001) ...
Adding new user `testuser2' (1001) with group `testuser2' ...
Creating home directory `/home/testuser2' ...
Copying files from `/etc/skel' ...
$ grep testuser2 /etc/passwd
testuser2:x:1001:1001:Test User,,,:/home/testuser2:/bin/bash     # ✅ bash shell
$ ls -ld /home/testuser2
drwxr-x--- 2 testuser2 testuser2 4096 Oct  7 18:04 /home/testuser2  # ✅ home dir + skel files
```

**Conclusion:** On Ubuntu, **`adduser` is the recommended command for interactively creating users** — it creates the home directory, copies skeleton files, picks `/bin/bash`, and prompts for a password. `useradd` creates only a bare `/etc/passwd` entry and is preferred inside scripts (with `-m -s /bin/bash` flags).

---

## Task 3: `journalctl`

### What it is

`journalctl` is the tool to query **systemd's journal** — the centralized binary log that collects kernel messages, service logs, and boot messages on modern Linux. It's the modern replacement for digging through `/var/log/*.log` files.

### Hands-on — real output (run on a systemd-based Linux node)

```bash
$ journalctl --version
systemd 252 (252.39-1~deb12u1)

$ journalctl -n 5 --no-pager                       # last 5 log lines, whole system
Oct 07 18:09:19 devops-hw-control-plane containerd[106]: time="..." level=error msg="unable to parse ..."
Oct 07 18:09:19 devops-hw-control-plane containerd[106]: time="..." level=error msg="unable to parse ..."
Oct 07 18:09:27 devops-hw-control-plane kubelet[693]: E1007 ... "Startup probe already exists for container" pod="kube-system/kube-scheduler-devops-hw-control-plane" ...

$ journalctl -u kubelet -n 5 --no-pager            # logs of ONE service (kubelet)
Oct 07 18:08:43 devops-hw-control-plane kubelet[693]: E1007 ... "Readiness probe already exists for container" pod="kube-system/coredns-7d764666f9-4cghr" ...
Oct 07 18:09:03 devops-hw-control-plane kubelet[693]: E1007 ... "Startup probe already exists for container" pod="kube-system/etcd-devops-hw-control-plane" ...
Oct 07 18:09:27 devops-hw-control-plane kubelet[693]: E1007 ... "Startup probe already exists for container" ...

$ journalctl -p err -b --no-pager | head           # only errors, current boot
-- No entries --
```

### Commands practiced for checking logs of a specific service

```bash
journalctl -u ssh.service            # all logs of the ssh service
journalctl -u nginx -n 50            # last 50 lines of nginx
journalctl -u docker -f              # follow (live tail) docker logs
journalctl -u cron --since today     # today's cron logs
journalctl -u kubelet --since "1 hour ago"
journalctl -p err -b                 # error+ messages this boot
journalctl -xe                       # jump to end with explanations
journalctl --disk-usage              # space used by the journal
```

**Key takeaway:** `journalctl -u <service>` is the #1 command for "why did my service fail?" — it shows the service's stdout/stderr plus systemd start/stop events in one place.

---

## Task 4: Linux Command Cheat Sheet (practiced)

| Category | Command | Purpose |
| :--- | :--- | :--- |
| **Files** | `ls -la`, `cd`, `pwd`, `cp -r`, `mv`, `rm -rf`, `mkdir -p`, `touch` | navigate & manage files/dirs |
| **View files** | `cat`, `less`, `head -n`, `tail -f` | read file contents |
| **Permissions** | `chmod 755 file`, `chown user:group file`, `umask` | change perms/ownership |
| **Users** | `adduser`, `useradd -m`, `usermod -aG sudo u`, `passwd`, `id`, `whoami`, `su -` | manage users |
| **Processes** | `ps aux`, `top`/`htop`, `kill -9 PID`, `jobs`, `systemctl status svc` | process control |
| **Logs** | `journalctl -u svc -f`, `dmesg`, `/var/log/syslog` | troubleshooting |
| **Disk** | `df -h`, `du -sh dir`, `mount`, `lsblk` | storage usage |
| **Network** | `ip a`, `ss -tulpn`, `ping`, `curl`, `dig`, `traceroute` | connectivity |
| **Search** | `grep -rn "txt" .`, `find / -name f`, `which`, `locate` | find things |
| **Archives** | `tar -xzf/-czf`, `zip`/`unzip` | compress/extract |
| **Packages** | `apt update && apt install pkg` | Debian/Ubuntu packages |
| **Links** | `ln`, `ln -s` | hard/soft links |
| **Shell** | `|`, `>`, `>>`, `2>`, `&&`, `;`, `$(cmd)`, `history` | pipes, redirection, substitution |

---

### Interview one-liners

* **Soft vs hard link:** hard links share the inode and survive deletion of the original; soft links store a path and break.
* **`adduser` vs `useradd`:** `adduser` is the friendly Debian/Ubuntu wrapper that sets up home dir/shell/skel interactively; `useradd` is the low-level tool for scripts.
* **`journalctl`:** query the systemd journal — `journalctl -u <unit>` for service logs, `-f` to follow, `-p err` for errors, `-b` for current boot.
