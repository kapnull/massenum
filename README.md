<h1 align="center">
  <img src="assets/massenumlogo.png" alt="massenum logo" width="350"/>
</h1>

A recon tool designed for pentesters working with large domain or IP scopes. It automates resolution, HTTP probing, subdomain enumeration with scope-based filtering, port scanning, tech fingerprinting, and screenshotting for up to hundreds of targets.

## Key Features

- Discovered subdomains are automatically filtered to only include those resolving to in-scope IPs
- Accepts both domains and IPs in a single targets file
- Subdomain discovery, port scanning, HTTP probing, and technology fingerprinting
- Automated screenshots of all live HTTP services
- Maintains a record of discovered but out-of-scope assets

## How Scope Filtering Works

When you provide a `targets.txt` file containing domains and IPs:

1. **Root domains** are resolved to their IPs
2. **A scope is built** from:
   - IPs explicitly listed in `targets.txt`
   - IPs that root domains resolve to
3. **Subdomains are discovered** via passive enumeration (subfinder)
4. **Only subdomains resolving to in-scope IPs are kept** for further testing
5. **Out-of-scope findings are logged** separately for your records

### Example

**Your targets.txt:**
```
example.com          # Resolves to 192.168.1.10
testsite.com         # Resolves to 192.168.1.11
192.168.1.12
```

**Subfinder discovers:**
- `api.example.com` → 192.168.1.10 ✅ **(kept - matches root domain IP)**
- `staging.example.com` → 192.168.1.12 ✅ **(kept - matches explicit IP in scope)**
- `legacy.example.com` → 10.0.0.50 ❌ **(filtered out - not in scope)**

Only the first two will be scanned further, while `legacy.example.com` is logged in `out_of_scope.txt`.

## Prerequisites

- subfinder
- dnsx
- httpx
- naabu
- gowitness

#### If you are lazy there's a script in the repo that does it for you
`prereqs.sh`

###### [!] It requires Go to be installed

## 📁 Output Structure
```
recon_20260109_1530/
├── domains/
│   ├── domains.txt              # Extracted root domains from input
│   ├── resolved.txt             # Successfully resolved root domains
│   └── resolved_with_IPs.txt    # Root domains with their IPs
├── ips/
│   ├── ips.txt                  # IPs extracted from input
│   └── scope.txt                # Complete IP scope (input IPs + resolved IPs)
├── subdomains/
│   ├── passive.txt              # All discovered subdomains (before filtering)
│   ├── resolved_with_IPs.txt    # Subdomains with their resolved IPs
│   ├── live.txt                 # IN-SCOPE subdomains only
│   └── out_of_scope.txt         # Out-of-scope subdomains (for reference)
├── ports/
│   ├── ip_ports.txt             # Open ports on IPs
│   ├── domain_ports.txt         # Open ports on root domains
│   └── subdomain_ports.txt      # Open ports on in-scope subdomains
├── http/
│   ├── live_domains.txt         # Live HTTP(S) root domains
│   ├── live_subdomains.txt      # Live HTTP(S) in-scope subdomains
│   └── tech_info.txt            # Technology fingerprinting results
└── screenshots/
    └── [automated screenshots of all live HTTP services]
```

## Installation
```bash
git clone https://github.com/anenstein/massenum.git
cd massenum
```

#### Install required tools

Use the provided tool installer:
```bash
chmod +x prereqs.sh
./prereqs.sh
```

This installs:
- Go-based tools: subfinder, dnsx, httpx, naabu
- System tools: gowitness
- libpcap-dev (for naabu)

#### Possible issues

###### It suddenly doesn't recognize the tools the script depends on?

just run `export PATH=$PATH:$(go env GOPATH)/bin`

## Usage

Create a `targets.txt` file with one domain or IP per line. Mixed input is supported.

**Example:**
```
example.com
company.org
192.168.1.10
192.168.1.11
10.0.50.100
```

Run the enumeration script:
```bash
chmod +x massenum.sh
./massenum.sh
```

## Output Summary

At the end of execution, you'll see:
```
[*] Done. Results saved in recon_20260109_135133/
[*] Summary:
    - Root domains: 296
    - IPs in original scope: 758
    - Total IPs in scope (including resolved): 874
    - Subdomains in scope: 280
    - Subdomains filtered out: 94
```
