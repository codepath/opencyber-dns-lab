#!/usr/bin/env bash
set -e

g='\033[0;32m'; n='\033[0m'

# Point the whole container at the lab resolver so `curl` (the "victim") resolves
# names through dnsmasq — this is what makes the Part 2 hijack literally work.
echo "nameserver 127.0.0.1" > /etc/resolv.conf

# Start the lab DNS resolver (poisonable). Runtime query log goes to its own file
# so it never mixes with the baked-in Part 3 dataset at /opt/dns-lab/logs/queries.log.
# Pre-create the runtime log student-owned so it's readable when the student greps it
# in Part 2, Step 4 (dnsmasq runs as user=student and appends to it).
touch /opt/dns-lab/dnsmasq-runtime.log && chown student:student /opt/dns-lab/dnsmasq-runtime.log
if [ -f /opt/dns-lab/dnsmasq.lab.conf ]; then
  dnsmasq --conf-file=/opt/dns-lab/dnsmasq.lab.conf 2>/dev/null || true
fi

# Start the credential-capture web server. It serves the lookalike page and appends
# any submitted credentials to /opt/dns-lab/captured.log itself, so its own stdout
# goes to a separate runtime log (keeps captured.log clean for the student to read).
touch /opt/dns-lab/captured.log && chown student:student /opt/dns-lab/captured.log
if [ -f /opt/dns-lab/web/capture_server.py ]; then
  ( cd /opt/dns-lab/web && python3 capture_server.py >/opt/dns-lab/capture-runtime.log 2>&1 & )
fi

echo
echo -e "   __   __   __   ___ "
echo -e "  /  \` /  \ |  \ |__  "
echo -e "  \__, \__/ |__/ |___ "
echo -e "   __       ___       "
echo -e "  |__)  /\   |   |__|  "
echo -e "  |    /--\  |   |  |  "
echo -e "        __   __   ___  "
echo -e "  ${g}\|/  ${n}/  \ |__) / _   "
echo -e "  ${g}/|\  ${n}\__/ |  \ \__/  "
echo
echo -e "Welcome to the ${g}DNS Security Lab${n} environment!"
echo
echo "GETTING STARTED:"
echo -e " ${g}*${n} Query the lab resolver:      dig @localhost <name>"
echo -e " ${g}*${n} Resolver config you'll edit: /opt/dns-lab/dnsmasq.lab.conf"
echo -e " ${g}*${n} Captured credentials land in: /opt/dns-lab/captured.log"
echo -e " ${g}*${n} Part 3 query-log dataset:    /opt/dns-lab/logs/queries.log"
echo -e " ${g}*${n} Follow along with the instructions at:"
echo -e "\thttps://github.com/codepath/opencyber-dns-lab"
echo

exec su - student
