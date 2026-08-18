# DNS Security Lab

This is the README documentation for the DNS Security Lab, produced and maintained by [CodePath.org](https://codepath.org).

## Quick Start

Want to jump into the lab? Navigate to the [Part 0 Instructions](./instructions/lab_part0.md) to get started!

## About this Lab

<img src="https://i.imgur.com/wSBU5vt.png" style="width: 75%; min-width: 350px;" alt="Screenshot of provided Docker Container printing welcome message for DNS Security Lab"></img>

The DNS Security Lab is designed to teach you how the internet's naming system really works — and how attackers abuse it. You'll start by resolving names by hand with `dig` to see why your computer trusts whatever answer its resolver hands back. Then you'll weaponize that trust: poison a resolver so a bank's login page points at a server you control, stand up a lookalike page, and capture a victim's credential. Finally you'll flip to defender and hunt through DNS query logs to find data an attacker smuggled out over DNS. Real DNS exploitation and real DNS defense, both in one container.

### Learning Objectives

- Read the DNS records (`A`, `CNAME`, `TXT`) that turn a name into an IP, and explain why a client trusts its resolver's answer
- Poison a resolver by editing its config so a trusted domain points at a host you control
- Harvest a credential by serving a lookalike login page at the victim's expected address and capturing what they submit
- Hunt an attack after the fact — spot the DNS redirect and recover data exfiltrated over DNS

### Lab Activities

0. [Setup: Run the lab environment with Docker](./instructions/lab_part0.md)
1. [Learn: How DNS Really Works](./instructions/lab_part1.md)
2. [Apply: The Hijack](./instructions/lab_part2.md)
3. [Challenge: The Hunt](./instructions/lab_part3.md)

## Technical Details

### Provided Tools

In the provided Docker container, you will find all the necessary tools and dependencies pre-installed. This includes:

- `dig` and `nslookup` - for querying DNS records by hand
- A local resolver (`dnsmasq`) - the resolver you'll poison
- `curl` - to request pages through the poisoned resolver
- A lookalike login page and capture server - the phishing site you'll stand up
- DNS query logs - the evidence you'll hunt through in Part 3

Part 3 also uses **[CyberChef](https://gchq.github.io/CyberChef/)** (in your browser) to decode the exfiltrated data.
