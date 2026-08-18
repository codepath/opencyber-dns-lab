# DNS Security Lab: Part 3 — The Hunt

[*(back to home)*](https://github.com/codepath/opencyber-dns-lab)

Lab Parts:

0. [Set up the lab environment using Docker.](./lab_part0.md)
1. [Learn: How DNS Really Works](./lab_part1.md)
2. [Apply: The Hijack](./lab_part2.md)
3. [Challenge: The Hunt](./lab_part3.md) (✅ You are here!)

## Part 3 | Challenge: The Hunt

**Estimated Time:** 60 minutes

**Environment:** Our provided Docker container (see [Part 0](./lab_part0.md) for setup instructions) + the [CyberChef](https://gchq.github.io/CyberChef/) web app

**Tools Needed:** `dig` (the recon tool from Part 1), the baked-in DNS query log, CyberChef (the same decoder tool from the CyberChef lab)

**[Back to home](https://github.com/codepath/opencyber-dns-lab)**

## Overview

Flip sides. You have spent two parts as the attacker; now you are the incident responder on Northwind Bank's security team. One of the workstations on the network may be compromised, and you suspect the attacker is using DNS itself to smuggle stolen data out of the network — a technique called **DNS exfiltration** (or **DNS tunneling**).

The idea is sneaky: firewalls almost always allow DNS out (port 53), because without it nothing works. So malware hides stolen data *inside the domain names it looks up*. Each lookup carries a chunk of the secret, encoded as a subdomain, to a **command-and-control (C2)** server the attacker owns. To the network it just looks like DNS. To the attacker's server, every query is a delivery.

Your job: find the exfiltration channel in the DNS logs, identify the C2 domain, and decode the smuggled data to recover the stolen secret.

## Instructions

### Step 1: Read the query logs

The security team exported the resolver's query log to `/opt/dns-lab/logs/queries.log`. Every line is one DNS lookup someone on the network made.

- [ ] Open the log and read the header, then skim the traffic:

  ```bash
  less /opt/dns-lab/logs/queries.log
  ```

  (Press `q` to quit `less`.) Each line follows this format:

  ```
  Mar 14 08:55:09 dnsmasq[812]: query[A] duckduckgo.com from 10.10.5.12
  ```

  That reads as: at this time, the resolver received a query of type `A` for `duckduckgo.com`, from the client at `10.10.5.12`.

- [ ] Get a feel for normal traffic. Most of these are ordinary sites — search engines, software updates, mail, CDNs. This is your baseline for "benign."

🎯 **Checkpoint 3.1**: you can read a log line and identify the queried domain and which client asked.

### Step 2: Spot the anomaly

In Part 2, Step 4 you read a resolver's query log and picked out your *own* attack — a name answering with an address it shouldn't. Same skill now, except this time you don't know going in what you're looking for. Malware doing DNS exfiltration doesn't look like a person browsing the web: somewhere in this log, something is behaving like a machine.

- [ ] Look for queries whose **subdomain looks like random garbage** rather than a readable name. Benign names are pronounceable (`fonts.gstatic.com`); exfiltrated data is a long, meaningless block of letters and digits, because it's *encoded*, not typed.

- [ ] **Watch for a decoy.** One legitimate-looking telemetry/CDN domain in this log is queried plainly and repeatedly — ordinary background noise, *not* your exfil channel. The exfil channel is the one whose **subdomains keep changing** into fresh random blocks (each carries new stolen data), all beaconing to a single shared parent domain from a single client. Telling the two apart is the point — read them, don't guess.

- [ ] Use `grep` to pull and group the odd lines (you don't have to read all 220 by eye — filter out the benign noise you've already cleared). From what's left, identify the **compromised client** and the **single C2 domain** every random-subdomain beacon shares — the registered domain those random labels all sit under. Name it.

- [ ] **Confirm where the stolen data was going.** Use the `dig @localhost` recon skill from Part 1 to look up *the C2 domain you found* and see what it answers with:

  ```bash
  dig @localhost A <the-C2-domain-you-found> +short
  ```

  <details>
  <summary>✅ What a right answer looks like (the shape, not the domain)</summary>

  The real C2 domain resolves to a single address in the `198.51.100.0/24` **documentation range** — an attacker-controlled server, deliberately *outside* the bank's own `203.0.113.0/24` range from Parts 1–2. If your candidate resolves to nothing, or to a bank address, it isn't the C2 — go back and look for the domain with the ever-changing random subdomains (the benign decoy won't resolve at all).

  </details>

🎯 **Checkpoint 3.2**: you've named the C2 domain (not the decoy), confirmed it resolves to an attacker-controlled address, and know which client was compromised.

### Step 3: Extract and decode the exfil channel

The random-looking subdomains aren't random — they're the stolen secret, chopped into pieces and **encoded** so each piece survives as a valid DNS label. Each beacon carries one chunk. Put the chunks back in the order they were sent (top to bottom in the log) and decode them, and the secret falls out.

- [ ] Pull the exfil queries out of the log — `grep` for **the C2 domain you identified** in Step 2 — and read the leftmost label (the encoded chunk) off each line, in order. Concatenate them into one long string, with no dots or spaces between them.

- [ ] **Recognize the encoding.** Look at the characters in your chunks: only `A`–`Z` and `2`–`7` — no `0`, `1`, `8`, `9`, and no lowercase. That exact 32-character alphabet is the fingerprint of **Base32**, a way to pack binary data into DNS-safe letters. (Quick sanity example: the Base32 string `NBSWY3DP` decodes to the text `hello`. Yours is longer but decodes the same way.)

- [ ] **Decode your string.** Either paste it into **[CyberChef](https://gchq.github.io/CyberChef/)** and add the **`From Base32`** operation, or decode it right here in the container:

  ```bash
  echo "<your-concatenated-string>" | base32 -d
  ```

  When the encoding and order are right, a readable secret falls out — and it's *obviously* readable (it looks like a flag), so you'll know at a glance whether you nailed the chunks and their order.

🎯 **Checkpoint 3.3**: you've decoded a human-readable secret. It looks like a flag: `CYB101{...}`.

### Step 4: Size up the breach (optional stretch)

You found the channel — now quantify it the way an incident report would. Using only the log:

- [ ] How **long** did the exfiltration run? (First beacon timestamp to last.)
- [ ] Roughly how many **bytes** left the network? Base32 packs 5 bits into each character, so a chunk of *N* characters carries about `N × 5 ÷ 8` bytes — add up your chunks.
- [ ] Which **one control** would have caught *this* channel, and why is it harder than "just block that domain"? (Hint: what gives DNS exfil away is the *pattern* — many random subdomains under one parent — not any single name.)

A real report doesn't stop at "we found exfil"; it says how much left, over how long, and how to stop the next one.

## You're done when

- you've named the **C2 domain** the compromised client beaconed to (not the decoy) and confirmed it resolves to an attacker-controlled address; and
- you've decoded the exfiltrated secret — a readable `CYB101{...}` flag.

Both are things you can confirm yourself: the flag only comes out readable if you found the right beacons, joined the chunks in order, and used the right encoding — a garbled result means one of those is off. Once you've recovered the flag, write down, in a few sentences (no single right answer): **how could a defender have caught this exfiltration earlier, and what makes DNS such an appealing channel for smuggling data out?**

**One last thing — confirm the C2 domain.** Once you've committed to your answer, this box has a self-check:

```bash
check-c2 <the-domain-you-found>
```

It tells you right away whether you named the right C2 domain — it never reveals the answer, only confirms yours. Run it *after* you've reasoned it out of the log, not as a shortcut around it: telling the real channel from the decoy is the whole skill.

### Tips for Success

- **`check-c2` keeps rejecting your answer?** Make sure you're giving it the **domain name** (like `sync.cdn-telemetry.test`), not the **IP address** it resolves to (a `198.51.100.x` number). A domain is a name made of words and dots; an IP is four numbers separated by dots. The question asks for the C2 *domain*, so your answer should read like a name, not a number.
- **`dig` on your candidate returns nothing?** Then it isn't the C2 — the real channel resolves (to a `198.51.100.x` address); the benign decoy doesn't resolve at all. Re-scan for the domain whose *subdomains keep changing* into fresh random blocks.
- **Decoded string is garbage?** Check three things: you kept *only* the random chunk labels (not the fixed `sync` label or the `.test` tail), you joined them in log order (top to bottom) with nothing between them, and you decoded as **Base32** (`From Base32` / `base32 -d`), not Base64.
- **Lost in 220 log lines?** `grep` out the noise you've already cleared as benign — `grep -v <pattern>` *excludes* matches, so you can hide the domains you've ruled out and look at what's left.
- **Leverage AI tools:** if you can see the pattern but not the command to extract it cleanly, ask an AI assistant for a `grep`/`awk` one-liner — then read it and make sure you understand what it matches before you trust its output.
