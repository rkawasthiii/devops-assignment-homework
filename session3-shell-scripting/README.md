# Session 3: Shell Scripting — Homework

> **Student:** Radhey Kawasthi (Enrollment: 10242)

## Task: System Information Script

[`system-info.sh`](./system-info.sh) does all of the following:

* Prints the **current date**, **hostname**, **username**
* Prints **disk usage** (`df -h`) and **running processes** (`ps aux`)
* Uses **variables** to store and reuse data
* Takes **user input** with `read -p`
* Creates a **directory** with `mkdir` and a **file** with `touch`
* Stores the process list in the file with **`>` output redirection**

## The Script

```bash
#!/bin/bash
# system-info.sh — System Information Script

current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "Current Date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"

echo "Disk Usage:"
df -h

echo "Top Running Processes:"
ps aux --sort=-%cpu | head -6

read -p "Enter a directory name to create: " dir_name
read -p "Enter a file name to create inside it: " file_name

mkdir -p "$dir_name"
touch "$dir_name/$file_name"
ps aux > "$dir_name/$file_name"
```

## How I Ran It

```bash
chmod +x system-info.sh
./system-info.sh
# inputs given: my-logs  and  processes.txt
```

## Real Output

```text
=========================================
        SYSTEM INFORMATION SCRIPT
=========================================
Current Date : Wed Oct  7 18:06:43 UTC 2026
Hostname     : 77a78fc6bef3
Username     : root
-----------------------------------------
Disk Usage:
Filesystem      Size  Used Avail Use% Mounted on
overlay        1007G   31G  926G   4% /
tmpfs            64M     0   64M   0% /dev
shm              64M     0   64M   0% /dev/shm
-----------------------------------------
Top Running Processes:
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   4372  3308 ?        Ss   18:06   0:00 bash -c ./system-info.sh
root          10  0.0  0.0   4372  3316 ?        S    18:06   0:00 /bin/bash ./system-info.sh
root          15  0.0  0.0   7080  2956 ?        R    18:06   0:00 ps aux --sort=-%cpu
-----------------------------------------
-----------------------------------------
Created directory : my-logs
Created file      : my-logs/processes.txt
Stored 4 lines of process info in the file.
First 5 lines of the file:
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   4372  3308 ?        Ss   18:06   0:00 bash -c ./system-info.sh
root          10  0.0  0.0   4372  3320 ?        S    18:06   0:00 /bin/bash ./system-info.sh
root          19  0.0  0.0   7080  2984 ?        R    18:06   0:00 ps aux
=========================================
```

## Verification — files were really created

```text
$ ls -la my-logs/
total 4
drwxr-xr-x 1 root root 512 Oct  7 18:06 .
drwxrwxrwx 1 root root 512 Oct  7 18:06 ..
-rw-r--r-- 1 root root 488 Oct  7 18:06 processes.txt
```

The generated `my-logs/processes.txt` is included in this folder as proof of the run.

## Concepts Used

| Concept | Where used |
| :--- | :--- |
| Variables | `current_date`, `host_name`, `user_name`, `dir_name`, `file_name` |
| Command substitution | `$(date)`, `$(hostname)`, `$(whoami)` |
| User input | `read -p "..." var` |
| `mkdir -p` | creates the directory (no error if it exists) |
| `touch` | creates the empty file |
| `>` redirection | `ps aux > file` overwrites the file with process list |
| `df -h` | human-readable disk usage |
| `ps aux` | all running processes |
| `head`, `wc -l` | inspecting the produced file |
