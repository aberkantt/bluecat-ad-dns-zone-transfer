# BlueCat AD DNS Zone Transfer

This repository contains a PowerShell script that exports all primary forward DNS zones from a Microsoft Active Directory DNS server and prepares them for import into BlueCat BAM using the built-in Bulk DNS Upload feature.

The script generates BlueCat-compatible CSV files. No BlueCat API or authentication is required.

---

## Overview

The script runs on a Windows DNS server and performs a bulk export of DNS records from all primary forward zones.  
Each zone is exported into a separate CSV file that can be uploaded through the BlueCat BAM web interface.

---

## Data Flow

Microsoft AD DNS  
→ PowerShell script  
→ CSV files  
→ BlueCat BAM Bulk DNS Upload

---

## Supported DNS Record Types

- A  
- AAAA  
- NS  
- CNAME  
- TXT  
- MX  
- SRV  

SOA records are intentionally excluded.

---

## Output Format

Each line in the generated CSV files follows this format:

add,<name>,<ttl>,<type>,<rdata>

Example:

add,www,3600,A,192.168.1.10  
add,@,3600,MX,10 mail.example.com  
add,_ldap._tcp,3600,SRV,0 100 389 dc01.example.com  

---

## Requirements

- Windows Server with DNS Server role
- Domain-joined system
- Windows PowerShell 5.1

PowerShell version can be checked with:

$PSVersionTable

---

## How to Run

1. Copy the script to the DNS server  
2. Open PowerShell as Administrator  
3. Run the script  

.\ad_dns_to_bluecat.ps1  

4. CSV files will be created under:

C:\DNS_Exports_BlueCat

5. Upload the CSV files via:

BlueCat BAM → DNS → Bulk DNS Upload

---

## Limitations

- Reverse lookup zones are not exported
- Multi-part TXT records are merged into a single value
- Duplicate record handling is managed by BlueCat during import
- Script is intended for bulk migration, not continuous synchronization

---

## Notes

This script intentionally avoids using the BlueCat REST API to keep the solution simple, version-independent, and suitable for enterprise environments.

---

## Disclaimer

All domain names, hostnames, and IP addresses used in sample outputs are placeholders.
