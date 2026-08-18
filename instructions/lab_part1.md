# DNS Security Lab: Part 1 — How DNS Really Works

[*(back to home)*](https://github.com/codepath/opencyber-dns-lab)

Lab Parts:

0. [Set up the lab environment using Docker.](./lab_part0.md)
1. [Learn: How DNS Really Works](./lab_part1.md) (✅ You are here!)
2. [Apply: The Hijack](./lab_part2.md)
3. [Challenge: The Hunt](./lab_part3.md)

## Part 1 | Learn: How DNS Really Works

**Estimated Time:** 45 minutes

**Environment:** Our provided Docker container (see [Part 0](./lab_part0.md) for setup instructions)

**Tools Needed:** `dig` (already installed for you)

**[Back to home](https://github.com/codepath/opencyber-dns-lab)**

## Overview

Every time you visit a website, your computer asks a **DNS resolver** to turn a name like `login.northwind-bank.test` into an IP address it can actually connect to. In this part you play the role of an attacker doing **recon** on your fictional target, Northwind Bank. You will read the three record types that matter most — `A`, `CNAME`, and `TXT` — and then uncover the flaw that makes the whole system exploitable: **you trust whatever your resolver tells you, and someone else might control that resolver.**

Each command below earns its keep. You are not memorizing DNS trivia — every query pries out one more piece of the target you will hijack in Part 2.

> [!NOTE]
> **Your recon tool: `dig`.** `dig` is the standard command-line tool for looking up DNS records. The shape you'll use all lab is `dig @localhost <TYPE> <name> +short`:
> - **`@localhost`** — *which resolver to ask.* Here it means "ask **this container's own** DNS resolver" (a small resolver called `dnsmasq` running inside the box), not the internet.
> - **`<TYPE>`** — the kind of record you want (`A`, `CNAME`, `TXT`, …). Leave it out and `dig` assumes `A`.
> - **`+short`** — strip `dig`'s noisy full output down to just the answer.
>
> Whatever `dig` hands back is exactly what your computer would use to decide where to connect.

## Instructions

### Step 1: Names to IPs with `dig A`

The most common DNS record is the **`A` record**: it maps a name to an IPv4 address. Before you can impersonate Northwind's login server, you need to know where the real one lives.

- [ ] Ask the resolver for the target's `A` record:

  ```bash
  dig @localhost A login.northwind-bank.test +short
  ```

- [ ] Read the single line that comes back. **Before you open the reveal, predict it:** what do you think that value represents, and why would an attacker doing recon want it?

<details>
<summary>✅ Check your result</summary>

You should get back exactly one line:

```
203.0.113.10
```

That is the **IP address of the real login server** — the host you are going to impersonate in Part 2. (Drop `+short` and the same answer shows up in a labeled `ANSWER SECTION`, the fuller form of the same lookup.)

</details>

- [ ] ✏️ **Write this IP down.** You'll watch it change in Part 2 when you poison the resolver, so you want the "before" value on hand.

🎯 **Checkpoint 1.1**: you can name the IP the login domain resolves to (check yours against the reveal above).

### Step 2: Record types — `CNAME`, `MX`, and `TXT`

A domain publishes more than just `A` records. Each record type answers a different question, and each is a potential intelligence leak. You ask for a specific type by naming it in the `dig` command.

**`CNAME` — aliases.** A `CNAME` says "this name is really just another name for that one." It reveals how a target's infrastructure is wired together.

- [ ] Query the `CNAME` for the bank's `secure` hostname:

  ```bash
  dig @localhost CNAME secure.northwind-bank.test +short
  ```

- [ ] Read what comes back. **Predict before you reveal:** what do you think this record is telling you about the relationship between the two names?

<details>
<summary>✅ Check your result</summary>

You should get back:

```
login.northwind-bank.test.
```

So `secure.northwind-bank.test` is just an alias for `login.northwind-bank.test`. Recon insight: both names point at the same login server, so poisoning one name and hijacking the login page covers both front doors.

</details>

**`MX` — mail servers (optional).** `MX` records say where email for a domain is delivered. Try it if you are curious:

  ```bash
  dig @localhost MX northwind-bank.test +short
  ```

**`TXT` — free-form text, and the leak.** `TXT` records hold arbitrary text. They are meant for things like email-authentication policies, but administrators constantly paste notes and reminders into them and forget the whole world can read them.

- [ ] Query the target's `TXT` record:

  ```bash
  dig @localhost TXT login.northwind-bank.test +short
  ```

- [ ] Read the text that comes back before opening the reveal — an administrator left something in here they shouldn't have.

<details>
<summary>✅ Check your result</summary>

You should see an internal operations note that was never meant to be public:

```
"northwind-ops: whoever answers on :53 IS the source of truth - lock down the resolver before launch"
```

Whoever wrote it is telling you exactly where Northwind is weak: **the resolver on port 53 is trusted as "the source of truth," and it has not been locked down.** That is your way in.

</details>

🎯 **Checkpoint 1.2**: you have recovered the clue hidden in the `TXT` record.

### Step 3: Who answers? — `dig @<resolver>`

Here's the insight the recon has been building toward. A DNS answer is only as trustworthy as the resolver that gave it. The `@` in `dig @<resolver>` chooses **which resolver you ask** — and different resolvers can give different answers for the same name.

- [ ] You have been asking the lab resolver this whole time with `@localhost` — the resolver running inside this container:

  ```bash
  dig @localhost A login.northwind-bank.test +short
  # -> 203.0.113.10  (the lab resolver's answer)
  ```

- [ ] Now think through what you just did. No central authority is *enforcing* that answer. `login.northwind-bank.test` resolves to `203.0.113.10` **only because the resolver you asked said so.** If you asked a different resolver — or if someone changed what *this* resolver says — you would get a different IP, and your computer would connect there instead, no questions asked.

> [!NOTE]
> **The core DNS trust problem:** your computer does not verify DNS answers. It connects to whatever IP the resolver returns. So whoever controls the resolver controls where your traffic goes. If an attacker can get you to trust a resolver they control — or can change the records in the resolver you already trust — they can silently send you to their server while the address bar still shows the name you expected.
>
> You just read a `TXT` record admitting Northwind's resolver is "the source of truth" and "not locked down." In Part 2, you become the one who controls that source of truth.

🎯 **Checkpoint 1.3**: you can explain why controlling the resolver means controlling the answer.

When you can read `A`/`CNAME`/`TXT` records and explain who answers a query, [**proceed to Part 2**](./lab_part2.md).
