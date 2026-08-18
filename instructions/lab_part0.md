# DNS Security Lab: Part 0 — Set up the lab environment using Docker

[*(back to home)*](https://github.com/codepath/opencyber-dns-lab)

Lab Parts:

0. [Set up the lab environment using Docker.](./lab_part0.md) (✅ You are here!)
1. [Learn: How DNS Really Works](./lab_part1.md)
2. [Apply: The Hijack](./lab_part2.md)
3. [Challenge: The Hunt](./lab_part3.md)

## Part 0 | Set up the lab environment using Docker

**Estimated Time:** 15 minutes

**Environment:** Your own computer

**Tools Needed:** Docker, a terminal

## Overview

Set up the single-container DNS lab and read the rules of engagement before you touch anything. Everything you need runs inside one container on your own machine — a small DNS resolver, a fake bank login page, and a credential-capture server, all fictional and all local.

## What you'll learn

By the end of this lab you will be able to:

- Read the DNS records (`A`, `CNAME`, `TXT`) that turn a name into an IP, and explain why your computer trusts whatever answer its resolver returns.
- Poison a resolver by editing its config so a trusted domain points at a host you control.
- Harvest a credential by serving a lookalike login page at the victim's expected address and capturing what they submit.
- Hunt for the attack after the fact by spotting the DNS redirect and the capture in the container's logs.

## Instructions

### Step 1: Install and start Docker

- [ ] Make sure you have Docker installed and running on your computer.
  - **Mac**: [Download Docker Desktop for Mac](https://docs.docker.com/desktop/install/mac-install/)
  - **Windows**: [Download Docker Desktop for Windows](https://docs.docker.com/desktop/install/windows-install/)
  - **Linux**: [Install Docker Engine](https://docs.docker.com/engine/install/) (or [Docker Desktop for Linux](https://docs.docker.com/desktop/install/linux/))
  - Once installed, open Docker Desktop and confirm it is running before continuing.

- [ ] Open a terminal on your computer:
  - **Mac**: Open **Terminal** (search "Terminal" in Spotlight with ⌘+Space)
  - **Windows**: Open **Command Prompt** or **PowerShell** (search either in the Start menu)
  - **Linux**: Open your system's terminal emulator

### Step 2: Run the lab container

- [ ] Pull and run the lab container:

  ```bash
  docker run -it --rm -p 8088:8080 ghcr.io/codepath/opencyber-dns-lab:latest
  ```

  The `-p 8088:8080` flag is optional — it is only needed if you want to open the hijacked page in your real browser as a bonus in Part 2. The core lab works without it.

- [ ] Watch your terminal for the welcome banner, then confirm you land at a `student@...:~$` prompt. It looks like this:

  ```text
  Welcome to the DNS Security Lab environment!

  GETTING STARTED:
   * Query the lab resolver:      dig @localhost <name>
   * Resolver config you'll edit: /opt/dns-lab/dnsmasq.lab.conf
   * Captured credentials land in: /opt/dns-lab/captured.log
   * Part 3 query-log dataset:    /opt/dns-lab/logs/queries.log
   * Follow along with the instructions at:
          https://github.com/codepath/opencyber-dns-lab

  student@a1b2c3d4e5f6:~$
  ```

  The `student@...:~$` prompt means you are now inside the container.

> [!TIP]
> If you have trouble pulling the image, you can build it yourself by cloning this repository:
>
> ```bash
> git clone https://github.com/codepath/opencyber-dns-lab.git
> cd opencyber-dns-lab
> make run     # builds the image, then runs it
> ```

> [!TIP]
> **Port `8088` already in use?** Map the container to a different **host** port instead: with the makefile it's `HOST_PORT=9090 make run`, or on a raw `docker run` change the number to the *left* of the colon, e.g. `-p 9090:8080`. Then open `http://localhost:9090` for the Part 2 browser preview. The lab still uses `8080` *inside* the container — only the host side changes.

🎯 **Checkpoint 0.1**: the container is running and you are at the `student` shell prompt.

### Step 3: Rules of engagement

This lab teaches a real attack: redirecting a domain to a page you control and capturing a credential from it. You are learning it so you can recognize and defend against it — not so you can use it.

> [!IMPORTANT]
> **Everything in this lab is fictional and local.**
> - The target, **Northwind Bank**, is a made-up company. `login.northwind-bank.test` is not a real domain (the `.test` suffix is reserved by the internet standards bodies precisely so it can never resolve to a real site).
> - Everything you need for this lab runs locally: you are attacking a resolver, a web page, and a log file that ship in the image. Keep it that way — point these tools only at the lab's own resolver and hosts, never at real external systems.
> - **Never** run these techniques against systems you do not own or have written authorization to test. Doing so is illegal in most countries, including under the U.S. Computer Fraud and Abuse Act.
>
> Treat this as an **authorized engagement**: you are a security professional testing Northwind Bank's defenses with their explicit permission, inside a sandbox they gave you.

- [ ] Read and acknowledge the rules of engagement before continuing.

When your environment is ready and you understand the rules, [**proceed to Part 1**](./lab_part1.md).
