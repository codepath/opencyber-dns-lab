# docker/Dockerfile — opencyber-dns-lab (CYB101 U4, absorbs U8 SET)
# Real resolver-based DNS: learn DNS, hijack a login page + capture a credential, then
# hunt DNS exfiltration. Replaces the /etc/hosts "DNS Tricks" lab, the Exploits project,
# and the SET credential-harvester mini-lab.
FROM ubuntu:22.04
ENV DEBIAN_FRONTEND=noninteractive

# dnsmasq = the poisonable resolver; dnsutils = dig/nslookup; python3 = tiny capture server;
# curl = the in-container "victim" that fetches the poisoned page; sudo = lets the student
# reload the (root-owned) resolver after editing its config.
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      dnsmasq dnsutils python3 curl ca-certificates sudo less nano && \
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash student && \
    echo 'student ALL=(root) NOPASSWD: /usr/bin/dnsmasq, /usr/bin/pkill, /usr/sbin/dnsmasq' \
      > /etc/sudoers.d/student-resolver && \
    chmod 0440 /etc/sudoers.d/student-resolver

# reload-resolver: apply edits the student makes to /opt/dns-lab/dnsmasq.lab.conf.
# Restarts dnsmasq from the lab config so a poisoned record takes effect.
RUN install -d -m 0755 /usr/local/bin && \
    printf '%s\n' \
      '#!/usr/bin/env bash' \
      'set -e' \
      'sudo pkill -x dnsmasq 2>/dev/null || true' \
      'sleep 0.3' \
      'sudo dnsmasq --conf-file=/opt/dns-lab/dnsmasq.lab.conf' \
      'echo "Lab resolver reloaded from /opt/dns-lab/dnsmasq.lab.conf"' \
      > /usr/local/bin/reload-resolver && chmod +x /usr/local/bin/reload-resolver

# Lab assets (see docker/files/):
#   dnsmasq.lab.conf   — resolver config with the poisonable record
#   web/               — the fictional "Northwind Bank" login page + capture_server.py
#   logs/queries.log   — baked-in DNS query log containing the Part 3 exfil channel
COPY docker/files/ /opt/dns-lab/
RUN chown -R student:student /opt/dns-lab

# Part 3 self-check: `check-c2 <domain>` hashes the student's C2-domain answer against the
# stored hash (answer not readable in the repo). On PATH so it works from anywhere in the box.
COPY --chmod=755 docker/check-c2.sh /usr/local/bin/check-c2

COPY --chmod=755 docker/entrypoint.sh /usr/local/bin/entrypoint.sh

# 53 = the lab resolver; 8080 = the served lookalike page + credential capture
EXPOSE 53/udp 8080
WORKDIR /home/student
ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]
CMD ["bash"]
