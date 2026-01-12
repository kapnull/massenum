#!/bin/bash

INPUT="targets.txt"
WORKDIR="recon_$(date +%Y%m%d_%H%M%S)"

mkdir -p "$WORKDIR"/{domains,ips,subdomains,ports,http,screenshots}

echo "[*] Extracting domains and IPs..."
grep -Eo '([a-zA-Z0-9_-]+\.)+[a-zA-Z]{2,}' "$INPUT" | sort -u > "$WORKDIR/domains/domains.txt"
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$INPUT" | sort -u > "$WORKDIR/ips/ips.txt"

echo "[*] Resolving domains to IPs..."
dnsx -l "$WORKDIR/domains/domains.txt" -resp -nc -o "$WORKDIR/domains/resolved_with_IPs.txt"

# Extract just the resolved domain names for further processing
awk '{print $1}' "$WORKDIR/domains/resolved_with_IPs.txt" | sort -u > "$WORKDIR/domains/resolved.txt"

# Build a comprehensive scope: IPs from targets.txt + IPs that root domains resolve to
echo "[*] Building IP scope from targets and resolved root domains..."
cat "$WORKDIR/ips/ips.txt" > "$WORKDIR/ips/scope.txt"
grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$WORKDIR/domains/resolved_with_IPs.txt" | sort -u >> "$WORKDIR/ips/scope.txt"
sort -u "$WORKDIR/ips/scope.txt" -o "$WORKDIR/ips/scope.txt"

echo "[*] Checking for live HTTP(S) on domains..."
httpx -l "$WORKDIR/domains/resolved.txt" -silent -threads 100 -o "$WORKDIR/http/live_domains.txt"

echo "[*] Subdomain enumeration..."
subfinder -dL "$WORKDIR/domains/domains.txt" -silent -o "$WORKDIR/subdomains/passive.txt"

echo "[*] Resolving subdomains..."
dnsx -l "$WORKDIR/subdomains/passive.txt" -resp -nc -o "$WORKDIR/subdomains/resolved_with_IPs.txt"

echo "[*] Filtering subdomains based on in-scope IPs..."
> "$WORKDIR/subdomains/live.txt"
> "$WORKDIR/subdomains/out_of_scope.txt"

while IFS= read -r line; do
    subdomain=$(echo "$line" | awk '{print $1}')
    ip=$(echo "$line" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | head -1)
    
    if [ -n "$ip" ]; then
        # Check if this IP is in the scope
        if grep -qFx "$ip" "$WORKDIR/ips/scope.txt"; then
            echo "$subdomain" >> "$WORKDIR/subdomains/live.txt"
        else
            echo "$subdomain [$ip]" >> "$WORKDIR/subdomains/out_of_scope.txt"
        fi
    fi
done < "$WORKDIR/subdomains/resolved_with_IPs.txt"

# Deduplicate the results
sort -u "$WORKDIR/subdomains/live.txt" -o "$WORKDIR/subdomains/live.txt"
sort -u "$WORKDIR/subdomains/out_of_scope.txt" -o "$WORKDIR/subdomains/out_of_scope.txt"

IN_SCOPE_COUNT=$(wc -l < "$WORKDIR/subdomains/live.txt" 2>/dev/null || echo "0")
OUT_SCOPE_COUNT=$(wc -l < "$WORKDIR/subdomains/out_of_scope.txt" 2>/dev/null || echo "0")
echo "[*] Subdomains in scope: $IN_SCOPE_COUNT"
echo "[*] Subdomains out of scope (filtered): $OUT_SCOPE_COUNT"

echo "[*] Port scanning IPs..."
naabu -l "$WORKDIR/ips/ips.txt" -p - -o "$WORKDIR/ports/ip_ports.txt"

echo "[*] Port scanning domains..."
naabu -l "$WORKDIR/domains/resolved.txt" -p - -o "$WORKDIR/ports/domain_ports.txt"

echo "[*] Port scanning in-scope subdomains..."
if [ -s "$WORKDIR/subdomains/live.txt" ]; then
    naabu -l "$WORKDIR/subdomains/live.txt" -p - -o "$WORKDIR/ports/subdomain_ports.txt"
fi

echo "[*] Fingerprinting technologies on live domains..."
httpx -l "$WORKDIR/http/live_domains.txt" -tech-detect -title -status-code -o "$WORKDIR/http/tech_info.txt"

echo "[*] Checking for live HTTP(S) on in-scope subdomains..."
if [ -s "$WORKDIR/subdomains/live.txt" ]; then
    httpx -l "$WORKDIR/subdomains/live.txt" -silent -threads 100 -o "$WORKDIR/http/live_subdomains.txt"
fi

echo "[*] Taking screenshots of domains..."
gowitness scan file -f "$WORKDIR/http/live_domains.txt" --screenshot-path "$WORKDIR/screenshots/"

echo "[*] Taking screenshots of subdomains..."
if [ -f "$WORKDIR/http/live_subdomains.txt" ]; then
    gowitness scan file -f "$WORKDIR/http/live_subdomains.txt" --screenshot-path "$WORKDIR/screenshots/"
fi

echo "[*] Done. Results saved in $WORKDIR/"
echo "[*] Summary:"
echo "    - Root domains: $(wc -l < "$WORKDIR/domains/domains.txt")"
echo "    - IPs in original scope: $(wc -l < "$WORKDIR/ips/ips.txt")"
echo "    - Total IPs in scope (including resolved): $(wc -l < "$WORKDIR/ips/scope.txt")"
echo "    - Subdomains in scope: $IN_SCOPE_COUNT"
echo "    - Subdomains filtered out: $OUT_SCOPE_COUNT"
