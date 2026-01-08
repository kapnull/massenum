<p align="center">
  <img src="assets/massenumlogo.png" alt="massenum logo" width="400"/>
</p>

<h1 align="center">massenum</h1>

A recon tool designed for pentesters working with large domain or IP scopes. It automates resolution, HTTP probing, subdomain enumeration, port scanning, tech fingerprinting, and screenshotting for up to hundreds of targets.

## Prerequisites
- subfinder
- dnsx
- httpx
- naabu
- assetfinder
- waybackurls
- gowitness

#### If you are lazy there's a script in the repo that does it for you
`prereqs.sh`

[!] It requires Go to be installed

## 📁 Output Structure
```
recon_20260107_1530/
├── domains/
│   ├── domains.txt
│   ├── resolved.txt
├── ips/
│   └── ips.txt
├── subdomains/
│   ├── passive.txt
│   └── live.txt
├── ports/
│   ├── ip_ports.txt
│   └── domain_ports.txt
├── http/
│   ├── live_domains.txt
│   └── tech_info.txt
├── screenshots/
│   └── [screenshots]
```
## Installation

```
git clone https://github.com/anenstein/massenum.git
cd mass-enum
```

#### Install required tools

Use the provided tool installer:
```
chmod +x prereqs.sh
./prereqs.sh
```
This installs:
- Go-based tools: subfinder, dnsx, httpx, naabu, assetfinder, waybackurls
- System tools: nmap, gowitness, jq

## Usage

Create a targets.txt file with one domain or IP per line. Mixed input is supported. Example:
```bash
example.com
72.184.216.34
portal.company.org/pos-web
```

Run the enumeration script:
```bash
chmod +x massenum.sh
./massenum.sh
```
