#!/bin/bash
INPUT="targets.txt"
WORKDIR="recon_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$WORKDIR"/{domains,ips,subdomains,ports,http,screenshots}

echo "[*] Extracting domains and IPs..."
grep -Eo '([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}' "$INPUT" | sort -u > "$WORKDIR/domains/domains.txt"
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$INPUT" | sort -u > "$WORKDIR/ips/ips.txt"

echo "[*] Resolving domains to IPs..."
dnsx -l "$WORKDIR/domains/domains.txt" -o "$WORKDIR/domains/resolved.txt"

echo "[*] Checking for live HTTP(S) on domains..."
httpx -l "$WORKDIR/domains/resolved.txt" -silent -threads 100 -o "$WORKDIR/http/live_domains.txt"

echo "[*] Subdomain enumeration..."
subfinder -dL "$WORKDIR/domains/domains.txt" -silent -o "$WORKDIR/subdomains/passive.txt"
dnsx -l "$WORKDIR/subdomains/passive.txt" -o "$WORKDIR/subdomains/live.txt"

echo "[*] Port scanning IPs..."
naabu -l "$WORKDIR/ips/ips.txt" -top-ports 1000 -o "$WORKDIR/ports/ip_ports.txt"

echo "[*] Port scanning domains..."
naabu -l "$WORKDIR/domains/resolved.txt" -top-ports 1000 -o "$WORKDIR/ports/domain_ports.txt"

echo "[*] Fingerprinting technologies on live domains..."
httpx -l "$WORKDIR/http/live_domains.txt" -tech-detect -title -status-code -o "$WORKDIR/http/tech_info.txt"

echo "[*] Taking screenshots..."
gowitness file -f "$WORKDIR/http/live_domains.txt" --threads 50 --timeout 10s -P "$WORKDIR/screenshots/"

echo "[*] Done. Results saved in $WORKDIR/"
