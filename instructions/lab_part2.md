# DNS Security Lab: Part 2 — The Hijack

[*(back to home)*](https://github.com/codepath/opencyber-dns-lab)

Lab Parts:

0. [Set up the lab environment using Docker.](./lab_part0.md)
1. [Learn: How DNS Really Works](./lab_part1.md)
2. [Apply: The Hijack](./lab_part2.md) (✅ You are here!)
3. [Challenge: The Hunt](./lab_part3.md)

## Part 2 | Apply: The Hijack

**Estimated Time:** 45 minutes

**Environment:** Our provided Docker container (see [Part 0](./lab_part0.md) for setup instructions)

**Tools Needed:** `dig`, `nano`, `curl`, the lab resolver config, the capture log (all already set up for you)

**[Back to home](https://github.com/codepath/opencyber-dns-lab)**

## Overview

In Part 1 you learned that whoever controls the resolver controls the answer. Now you *become* that controller. You will edit the lab resolver's configuration so `login.northwind-bank.test` points at a web server **you** control inside the container, load the lookalike login page a victim would see, submit a credential, and watch it land in your capture log.

This is the payoff. The DNS fundamentals from Part 1 turn into a working credential-harvesting attack.

## Instructions

### Step 1: Poison the resolver

The lab resolver reads its records from a config file at `/opt/dns-lab/dnsmasq.lab.conf`. You can edit it. That is the entire vulnerability — the "source of truth" is a text file, and you have a pencil.

A web server is already running inside this container, listening on port `8080`. It serves a **lookalike Northwind Bank login page** — a copy of the bank's real sign-in screen, hosted by you (you'll load it yourself in Step 2). The container's own address is `127.0.0.1`. So your goal is to make `login.northwind-bank.test` resolve to `127.0.0.1` — your server — instead of the real `203.0.113.10`, quietly sending anyone who visits the bank to your page.

- [ ] Open the resolver config in the `nano` editor:

  ```bash
  nano /opt/dns-lab/dnsmasq.lab.conf
  ```

- [ ] Use the **arrow keys** to scroll down to the Northwind records. Find the real login `A` record and **comment it out** by putting a `#` at the front of the line:

  ```
  #host-record=login.northwind-bank.test,203.0.113.10
  ```

- [ ] Keep scrolling to the `PART 2 — POISON THE RESOLVER` block near the bottom and **uncomment** the poisoned line by removing its leading `#`:

  ```
  host-record=login.northwind-bank.test,127.0.0.1
  ```

- [ ] Save and exit `nano` (`Ctrl+O`, then `Enter`, then `Ctrl+X`).

- [ ] Apply your change by reloading the resolver:

  ```bash
  reload-resolver
  ```

  You should see `Lab resolver reloaded from /opt/dns-lab/dnsmasq.lab.conf`.

- [ ] Confirm the poison took effect. Predict what this should answer now, then run it:

  ```bash
  dig @localhost A login.northwind-bank.test +short
  ```

<details>
<summary>✅ Check your result</summary>

It should now answer:

```
127.0.0.1
```

That is **your** server. Compare it to the IP you wrote down in Part 1: the same name that answered **`203.0.113.10`** a moment ago now answers **`127.0.0.1`** — you just changed where `login.northwind-bank.test` points, for everyone who asks this resolver.

</details>

> [!WARNING]
> **See *two* addresses — `127.0.0.1` **and** `203.0.113.10`?** You uncommented the poison but left the real record active, so the name now has two `host-record` lines. This is the sneaky one: `curl` may still reach your page, so the attack *looks* like it worked — but the poison isn't clean, and a defender would spot both answers. Put a `#` in front of the real `203.0.113.10` line, save, and `reload-resolver` until `dig` returns **only** `127.0.0.1`.

🎯 **Checkpoint 2.1**: `dig A login.northwind-bank.test` now returns `127.0.0.1` (and *only* that), the attacker-controlled host.

### Step 2: Serve the lookalike page

The whole container now resolves names through the resolver you just poisoned (its `/etc/resolv.conf` points at `localhost`). So when *anything* in this container asks for `login.northwind-bank.test`, it gets sent to your server. Let's play the victim and visit the "bank."

- [ ] Request the login page exactly the way a browser would, using `curl`:

  ```bash
  curl http://login.northwind-bank.test:8080/
  ```

  You will get back the HTML of a **Northwind Bank sign-in page** — served by *your* server, at a URL that still says `login.northwind-bank.test`. The victim typed a name they trusted; DNS quietly sent them to you.

> [!TIP]
> **See it the way a victim would.** If you started the container with `-p 8088:8080`, open **http://localhost:8088** in your real web browser to view the lookalike page rendered — it's far more convincing (and more fun) than raw HTML. (Your browser uses your computer's DNS, not the lab resolver, so this is just a preview of the *page*; the real DNS redirect is the `curl` above, which resolves the *name* through the poisoned resolver.)

🎯 **Checkpoint 2.2**: requesting `login.northwind-bank.test` serves *your* lookalike page.

### Step 3: Capture a credential

A phishing page is only useful if it steals something. This login form POSTs whatever the victim types to your capture server, which quietly logs it and then shows a bland "maintenance" page so the victim does not get suspicious.

- [ ] Play the victim submitting their login. Send a username and password to the form the same way the browser would when the victim clicks "Sign In":

  ```bash
  curl -X POST http://login.northwind-bank.test:8080/login \
    --data 'username=j.harper&password=P@ssw0rd123'
  ```

  You will get back a "We'll be right back / scheduled maintenance" page — exactly what the victim would see, and exactly what keeps them from realizing anything went wrong.

> [!TIP]
> **Even better, be the victim yourself.** If you opened `http://localhost:8088` in your browser (Step 2), type any username/password into the form and click **Sign In** — then read the capture below and watch *your own* submission show up. Seeing the page and submitting like a real person is the visceral version of the same attack.

- [ ] Now read what you captured:

  ```bash
  cat /opt/dns-lab/captured.log
  ```

- [ ] Look for the credential you just submitted, then check it against the reveal.

<details>
<summary>✅ Check your result</summary>

You should see a line like:

```
[2026-07-24 18:07:32] CAPTURED from 127.0.0.1 -> username='j.harper' password='P@ssw0rd123'
```

That is a harvested credential. In a real engagement, this is the moment the assessment succeeds — you now hold a working login for the target.

</details>

🎯 **Checkpoint 2.3**: the captured credential appears in `/opt/dns-lab/captured.log`.

### Step 4: See your attack in the logs

Every lookup the resolver answers gets written to its live query log at `/opt/dns-lab/dnsmasq-runtime.log`. Your poison is in there right now — and reading a query log for "answers that don't belong" is exactly the skill you'll use, unaided, in Part 3. Meet it here first, on an attack you already understand because you *ran* it.

- [ ] Pull your poisoned name out of the resolver's query log:

  ```bash
  grep "login.northwind-bank.test" /opt/dns-lab/dnsmasq-runtime.log
  ```

  <details>
  <summary>✅ Check your result</summary>

  You'll see the lookups your `dig` and `curl` triggered, each answered from your poisoned config:

  ```
  query[A] login.northwind-bank.test from 127.0.0.1
  config login.northwind-bank.test is 127.0.0.1
  ```

  The `config ... is 127.0.0.1` line is the tell: the bank's login name is resolving to `127.0.0.1` instead of its real `203.0.113.10`. To a defender scanning this log, *that* is the fingerprint of a hijack — an internal name answering with an address it never should. Reading a query log for exactly this kind of "answer that doesn't belong" is the whole job of Part 3.

  </details>

🎯 **Checkpoint 2.4**: you can find your own attack in the resolver's query log — the poisoned name answering with the wrong address.

### Step 5: Debrief — why it worked

Step back and notice what was — and was not — required to pull this off. You never broke the victim's computer. You never cracked a password. You never touched the real Northwind login server (it was never even reachable). All you did was **change one line in a resolver's config**, and the victim's own trust did the rest:

```
  victim asks for  login.northwind-bank.test
            │
            ▼
   ┌─────────────────────┐   you changed one line, so it answers…
   │  poisoned resolver  │ ──────────────► 127.0.0.1  (YOUR server)
   └─────────────────────┘         …instead of the real 203.0.113.10
            │
            ▼
   your lookalike login page  ──victim types their password──►  captured.log
```

The address bar still said `login.northwind-bank.test`, so the page looked legitimate, so they typed their password.

> [!NOTE]
> **You just ran a man-in-the-middle (MITM) attack.** By controlling the resolver, you inserted *yourself* between the victim and the server they meant to reach — the defining move of a MITM. The specific technique is **DNS spoofing** (a.k.a. DNS poisoning), and the payoff is **credential harvesting** — the same idea behind tools like the Social-Engineering Toolkit (SET), which you'll use directly in the SET lab. The technical trick only sets the stage; the attack succeeds because a human trusted the name in the address bar, and DNS gives them no built-in way to tell the real login server from an attacker who controls the resolver. **The human is the last line of defense, and the human is what the attack targets.**

- [ ] In your own words, write down two things: (1) why the victim believed the page was real, and (2) one defense that would have protected them (for example, a password manager that only autofills on the *real* domain, or hardware-key multi-factor authentication that a lookalike page cannot replay).

### Step 6: Poison the whole domain (optional stretch)

You poisoned one record. An attacker who controls the resolver rarely stops at one — they can take the *whole* domain in a single stroke.

- [ ] Instead of another single `host-record`, add a **wildcard** that redirects *every* name under `northwind-bank.test` to your server. Add this line to the config and `reload-resolver`:

  ```
  address=/northwind-bank.test/127.0.0.1
  ```

- [ ] Confirm that names you never touched individually now point at you — including one you invent on the spot:

  ```bash
  dig @localhost A vpn.northwind-bank.test +short
  ```

  It answers `127.0.0.1`, even though there's no `vpn` record anywhere — the wildcard catches every subdomain. One line just hijacked the entire domain: a blunter, wider technique than the surgical single-record poison, and a sharp reminder of how much "controls the resolver" really hands an attacker.

When you have a captured credential and can explain why the attack works, [**proceed to Part 3**](./lab_part3.md).
