#!/bin/bash
# system-info.sh — Session 3 Homework: System Information Script
# Author: Radhey Kawasthi (10242)
# Demonstrates: variables, read -p, mkdir, touch, echo, df, ps, > redirection

# --- Variables storing system data ---
current_date=$(date)
host_name=$(hostname)
user_name=$(whoami)

echo "========================================="
echo "        SYSTEM INFORMATION SCRIPT        "
echo "========================================="
echo "Current Date : $current_date"
echo "Hostname     : $host_name"
echo "Username     : $user_name"
echo "-----------------------------------------"

echo "Disk Usage:"
df -h
echo "-----------------------------------------"

echo "Top Running Processes:"
ps aux --sort=-%cpu | head -6
echo "-----------------------------------------"

# --- Take user input with read -p ---
read -p "Enter a directory name to create: " dir_name
read -p "Enter a file name to create inside it: " file_name

# --- Create directory + file ---
mkdir -p "$dir_name"
touch "$dir_name/$file_name"

# --- Store running processes into the file using > redirection ---
ps aux > "$dir_name/$file_name"

echo "-----------------------------------------"
echo "Created directory : $dir_name"
echo "Created file      : $dir_name/$file_name"
echo "Stored $(wc -l < "$dir_name/$file_name") lines of process info in the file."
echo "First 5 lines of the file:"
head -5 "$dir_name/$file_name"
echo "========================================="
