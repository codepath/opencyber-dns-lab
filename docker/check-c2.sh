#!/bin/sh
# check-c2 — self-check for the DNS lab Part 3: did you name the right C2 domain?
# The answer is stored ONLY as the hash below, so this file never reveals it. Your
# input is normalized to its registered domain (the last two labels) before hashing,
# so either the bare registered domain or the fuller beacon parent you might submit
# both match.
ANSWER_HASH="e9c1a0e269043deaf1dc46919b58bca184f10fad69841e71ae5f223a85c3d5f5"
if [ -z "$1" ]; then
  echo "Usage: check-c2 <domain>    e.g.  check-c2 some.domain.test"
  exit 2
fi
g=$(printf '%s' "$1" | tr 'A-Z' 'a-z' | sed 's/\.$//')
reg=$(printf '%s' "$g" | awk -F. '{ if (NF>=2) print $(NF-1)"."$NF; else print $0 }')
h=$(printf '%s' "$reg" | sha256sum | cut -d' ' -f1)
if [ "$h" = "$ANSWER_HASH" ]; then
  echo "CORRECT - that's the C2 domain the compromised client was beaconing to."
else
  echo "NOT THIS ONE - re-check. The C2 domain is the one whose subdomains keep changing into"
  echo "random Base32 blocks (not the plainly-queried telemetry/CDN decoy). Try the registered"
  echo "domain those random subdomains all share."
fi
