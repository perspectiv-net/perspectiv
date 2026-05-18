# Perspectiv — Deployment Guide

This guide walks through deploying Perspectiv on a single Linux host
using the official Docker images. The resulting stack is a complete
network monitoring platform with TLS, automatic certificate renewal,
and built-in backups.

---

## 1. Prerequisites

### Hardware sizing

Match your fleet size to the corresponding plan tier. The hardware
recommendations align directly with Perspectiv's pricing tiers — pick
the row that matches your plan and you have the host you need.

| Plan tier | Devices | vCPUs | RAM | Disk | Typical actual usage | Notes |
|-----------|---------|-------|-----|------|----------------------|-------|
| **Starter** | Up to 100 | 2 | 8 GB | 250 GB SSD | 5–7 GB RAM, ~50 GB disk | Single-host evaluation or small office |
| **Professional** | Up to 250 | 4 | 16 GB | 500 GB SSD | 10–13 GB RAM, ~120 GB disk | Typical SMB / multi-site |
| **Business** | Up to 500 | 6 | 32 GB | 1 TB SSD | 18–25 GB RAM, ~250 GB disk | Larger SMB / regional ops |
| **Enterprise** | Up to 1,000 | 8 | 64 GB | 2 TB SSD | 35–45 GB RAM, ~500 GB disk | Split-tier (separate PostgreSQL host) recommended |
| **Scale** | 1,000+ | Custom | Custom | Custom | Sized per deployment | Multi-tier, multi-site — [contact sales](mailto:sales@perspectiv.net) |

> **How the RAM numbers were derived.** The "Recommended RAM" column is a comfortable production sizing with headroom for NetFlow bursts, alert storms, backup runs, and TimescaleDB chunk compaction. The "Typical actual usage" column is the steady-state workload memory you'll observe in `free -h` once the install has warmed up — buffers/cache excluded (those reclaim instantly when needed). Starter was validated on a 100-device production install running for 37+ days: ~6 GB workload, 28% reported memory with cache included, 91% available after reclaim. The remaining tiers scale roughly linearly from there (1 GB fixed overhead + ~50 MB per fully-monitored device + room for NetFlow / syslog volume).
>
> **How the disk numbers were derived.** NetFlow is the dominant driver — at default 7-day retention with TimescaleDB compression enabled, a single fully-monitored device generates ~1 GB of compressed flow data per week. Lab observation on a 38-device install: 45 GB total disk after 2 weeks (mostly netflow_flows chunks + per-chunk indexes that don't compress). Linear extrapolation gives the per-tier disk targets above with ~30-40% headroom for spike traffic and growth. **These numbers assume NetFlow is enabled and ingesting flows from your routers/firewalls.** Without NetFlow (SNMP-polling-only deployments) disk usage drops to roughly 10% of these figures, so a Starter SNMP-only install fits comfortably in 50 GB.
>
> **About the disk recommendations relative to other tools.** No serious network monitoring product with NetFlow + syslog + 7-day retention runs comfortably in 100 GB. SolarWinds NPM with NTA recommends 250 GB+ for similar workloads; PRTG can require similar. Perspectiv's disk footprint is competitive — sometimes better thanks to TimescaleDB compression — but the bytes have to land somewhere. If disk is the binding constraint, two tunable knobs reduce footprint substantially: shorten NetFlow retention to 3 days (cuts the largest table by ~60%), or disable NetFlow ingestion entirely if your use case doesn't need flow visibility.
>
> **Memory display fixed in v0.6.16.** Earlier versions reported `(total - free) / total`, which Linux's aggressive disk caching inflated to 95-100% on long-running boxes. v0.6.16 subtracts buffers + cached so the percentage matches `free -h`'s "available" column. If you're upgrading from v0.6.15 or earlier and your "memory %" dashboard chart suddenly drops, that's the fix landing — not a real change in workload.

> **Split-tier deployment** (separate PostgreSQL host) becomes the right call at the Enterprise tier — at 1,000 devices the database benefits from dedicated resources and the Perspectiv app from the freed memory. [Contact support](mailto:sales@perspectiv.net) for the split-tier reference architecture.

### Software

- **Ubuntu 22.04 LTS or 24.04 LTS** (other modern Linux distros work; these are tested)
- **Docker Engine 24+** with the compose plugin
- Outbound internet access on :443 (Let's Encrypt, image pulls)
- Inbound :80 + :443 reachable publicly (for Let's Encrypt HTTP-01)

Install Docker if not already present:

```bash
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker $USER   # log out/in after this
```

### DNS

Point an A record at your deployment host **before** starting the stack.
Let's Encrypt's certificate issuance will fail if the hostname doesn't
already resolve to this box.

```
monitor.acme-corp.com.   A    203.0.113.42    (your public IP)
```

---

## 2. Install

```bash
# 1. Clone the deployment repo (this is the public release-snapshot
#    repo — perspectiv-net/perspectiv. The "perspectiv-source" repo
#    holds the application code and is private; you don't need it for
#    deployment.)
git clone https://github.com/perspectiv-net/perspectiv.git
cd perspectiv

# 2. Configure
cp .env.example .env
vim .env                        # fill in hostname, email, DB password

# 3. Start
docker compose up -d

# 4. Watch startup (first boot takes ~90 s — image pull + DB init)
docker compose logs -f perspectiv
```

### ⚠ Migrating from an existing Perspectiv install?

If you're standing up Perspectiv on a new host and plan to **restore a
backup** from an existing instance, stop here before proceeding. You
need to seed the encryption keyring first — otherwise the new container
will auto-generate a fresh key on first boot, and any encrypted device
credentials in your backup will be permanently unrecoverable on this
host.

```bash
# On the SOURCE host, grab the existing key:
#   native install:  /opt/perspectiv/perspectiv.key
#   docker install:  docker run --rm -v perspectiv_perspectiv-keyring:/k alpine cat /k/perspectiv.key

# Copy it to this host (any path will do):
scp source-host:/opt/perspectiv/perspectiv.key /tmp/perspectiv.key

# Seed the keyring volume BEFORE starting the app
docker volume create perspectiv_perspectiv-keyring
docker run --rm -v perspectiv_perspectiv-keyring:/kr -v /tmp:/src alpine \
    sh -c "cp /src/perspectiv.key /kr/perspectiv.key && chmod 600 /kr/perspectiv.key"

# NOW start the stack (step 3 above)
docker compose up -d

# And run the restore (step 4 + onwards)
./scripts/restore.sh /path/to/source-host-backup.dump
```

Fresh installs with no data to migrate don't need this — the app
auto-generates its own key on first boot and persists it to the same
volume.

When you see `[100%] Ready.` in the logs, Perspectiv is serving.
**Exit the log view with `Ctrl+C`** (the service keeps running — you
were just watching the logs), then browse to:

```
https://<the value of PERSPECTIV_HOSTNAME in your .env>
```

For example, if your `.env` has `PERSPECTIV_HOSTNAME=monitor.acme-corp.com`:
```
https://monitor.acme-corp.com
```

---

### Lab / LAN-only testing

If you're testing on an internal network without public DNS, two
caveats apply:

1. **Let's Encrypt can't issue certificates for internal IPs or
   domains that aren't publicly resolvable.** Traefik will fall back
   to a self-signed certificate and your browser will show a security
   warning — click through it for testing. Never use a self-signed
   cert in production.

2. **Traefik routes by Host header**, so the URL you visit must match
   `PERSPECTIV_HOSTNAME` in `.env`. For IP testing, set it to the IP:
   ```
   PERSPECTIV_HOSTNAME=192.168.4.74
   ```
   Restart with `docker compose down && docker compose up -d`.

For the cleanest LAN-test experience (skip TLS + Traefik), drop this
`docker-compose.override.yml` alongside `docker-compose.yml` — compose
auto-merges both:

```yaml
services:
  perspectiv:
    ports:
      # Expose the app directly on host port 5000 for LAN access.
      # REMOVE this file before going to production.
      - "5000:5000"
```

Then hit `http://<your-ip>:5000` directly — plain HTTP, no Traefik,
no cert warnings.

### Air-gapped or BYO-certificate deploy

If your host can't (or won't) accept inbound TCP/80 from the public
internet — corporate firewall, internal-only deploy, air-gapped network
— Let's Encrypt's HTTP-01 challenge cannot succeed. You have two
production-grade options that don't require port 80.

**Option A — DNS-01 challenge.** Lets Encrypt validates by reading a
TXT record on your domain instead of hitting port 80. Requires that
you (or Traefik) can write DNS records on the zone — Traefik supports
Cloudflare, Route53, DigitalOcean, Azure, Gandi, and ~50 others.

In `traefik/traefik.yml`, swap the resolver block from HTTP to DNS:

```yaml
certificatesResolvers:
  letsencrypt:
    acme:
      email: ${LETSENCRYPT_EMAIL}
      storage: /letsencrypt/acme.json
      dnsChallenge:
        provider: cloudflare      # or route53, digitalocean, etc.
        delayBeforeCheck: 30
```

Then mount the provider's API credentials into Traefik via the
`environment:` block in `docker-compose.yml`. Traefik's docs list the
exact env-var names per provider. Once Traefik can publish a TXT
record, certs issue normally — no port 80 required.

**Option B — bring your own certificate.** Most appropriate for
internal-only deploys with a corporate CA. Drop the `certResolver`
label on the `perspectiv` service in `docker-compose.yml` (so Traefik
stops trying ACME), then declare your cert in `traefik/dynamic.yml`:

```yaml
tls:
  certificates:
    - certFile: /certs/perspectiv.crt
      keyFile:  /certs/perspectiv.key
  stores:
    default:
      defaultCertificate:
        certFile: /certs/perspectiv.crt
        keyFile:  /certs/perspectiv.key
```

…and mount `/certs` into Traefik:

```yaml
# in docker-compose.yml under the traefik service
volumes:
  - /opt/perspectiv-deploy/certs:/certs:ro
```

Drop `perspectiv.crt` (full chain — leaf + intermediates concatenated)
and `perspectiv.key` into `/opt/perspectiv-deploy/certs` with mode 0600
on the key. `docker compose restart traefik` and you're serving HTTPS
with the corporate cert. Renewals are your responsibility (set a
calendar reminder for 30 days before expiry).

**Verification**, regardless of which path you took:

```bash
curl -vI https://your-perspectiv-host 2>&1 | grep -E "issuer|expire date|HTTP/"
```

Issuer should be Let's Encrypt (Option A) or your corporate CA
(Option B). Expiry should be ≥ 30 days out.

Default login on a fresh install:

```
Username:  admin
Password:  admin123
```

**You will be required to set a new password before reaching the dashboard.** The forced-change page enforces Perspectiv's password policy (minimum 10 characters with at least one uppercase letter, one lowercase letter, one digit, and one symbol). Once you've changed the password, the rest of the dashboard unlocks.

---

## 3. Post-install configuration

### Change the default admin password

Log in → top-right menu → Settings → Users → Edit `admin` → New password.

### Add your first monitored device

Devices → Add Device → fill in hostname / IP and SNMP credentials.
Polling begins within 60 seconds.

### Configure SMTP (for alert emails)

Settings → SMTP → Server / Port / Username / Password / TLS.
Test with the "Send test email" button.

### Apply your license key (if applicable)

Settings → License → paste key → Save.

---

## 4. Daily operations

### Backups

The `scripts/backup.sh` utility dumps the database to
`./backups/perspectiv-<timestamp>.dump`.

For daily automated backups with 14-day retention, add to `/etc/crontab`:

```cron
30 2 * * *  cd /opt/perspectiv-deploy && ./scripts/backup.sh && \
            find ./backups -name '*.dump' -mtime +14 -delete
```

Test restore periodically using `scripts/restore.sh <path-to-dump>`.
Restore drops and recreates the database — take a safety backup first.

### Upgrades

```bash
# To latest stable:
./scripts/upgrade.sh

# To a specific version:
./scripts/upgrade.sh v1.2.0
```

The upgrade script takes a backup, pulls the new image, runs any
startup migrations, and waits for the app to report healthy. Rolling
back is just another `upgrade.sh <older-version>`.

### Monitoring the monitor

The container exposes a health endpoint:

```bash
curl -sf https://monitor.acme-corp.com/health | jq
```

A `200 OK` with `{"status":"ok"}` means the app is serving requests
and has a live DB connection.

For systemd-level monitoring, wrap docker compose status in a shell
script that exits non-zero on unhealthy:

```bash
#!/usr/bin/env bash
docker compose -f /opt/perspectiv-deploy/docker-compose.yml ps \
    --format json | jq -e '.[] | select(.Health=="unhealthy")' >/dev/null
[[ $? -eq 1 ]]                    # jq exits 1 when no match → healthy
```

---

## 5. Agent installation (remote sites)

For sites you want to monitor from the far side of a firewall, install
the agent on a small Linux VM or Windows host at that site.

Download the appropriate binary from the latest release:

- **Linux**: `perspectiv-agent-linux-x86_64.tar.gz`
- **Windows**: `perspectiv-agent-windows-x86_64.zip`

Get them at: `https://github.com/perspectiv-net/perspectiv/releases/latest`
or from your `download.perspectiv.net` distribution URL.

Install:

```bash
# Linux
tar -xzf perspectiv-agent-linux-x86_64.tar.gz
cd perspectiv-agent
sudo ./install-linux.sh \
    --server https://monitor.acme-corp.com \
    --api-key "paste-from-Settings-Agents-AddAgent"
```

The agent runs as a systemd service and reports back to your central
Perspectiv every 60 seconds.

---

## 6. Troubleshooting

### Certificate issuance fails

```
level=error msg="Unable to obtain ACME certificate"
```

Causes, in order of likelihood:

1. **DNS not propagated** — `dig +short monitor.acme-corp.com` must
   return your server's public IP. Wait 5 minutes after adding the
   record, or force flush caches.
2. **Port 80 blocked upstream** — Let's Encrypt connects to your
   server on :80 for the HTTP-01 challenge. Test from outside:
   `curl -v http://monitor.acme-corp.com/.well-known/`. If that
   times out, check firewall / security group rules.
3. **Rate limit** — Let's Encrypt allows ~5 issuance attempts per
   hostname per hour. Wait and retry.

### External requests return 404 page not found

Traefik routes by Host header. If `PERSPECTIV_HOSTNAME` in `.env` doesn't
match the hostname in your inbound requests (for example `.env` has
`192.168.4.39` but external requests arrive with `Host: app.example.com`),
Traefik finds no matching router and returns 404.

Diagnose:

```bash
docker logs perspectiv-traefik 2>&1 | grep 404
```

Fix: update `.env` to your public hostname and restart:

```bash
docker compose down
docker compose up -d
```

The same `PERSPECTIV_HOSTNAME` value works for both LAN access (via DNS
hairpin NAT pointing the public hostname back at the LAN IP) and
external access. Don't try to support multiple hostnames unless you
truly need to — the single-hostname pattern is what's tested in CI.

If you genuinely need both direct-by-LAN-IP access AND public-domain
access on the same install, edit the Traefik routing label in
`docker-compose.yml` to:

```yaml
- "traefik.http.routers.perspectiv.rule=Host(`192.168.4.X`) || Host(`their-domain.com`)"
```

…but be aware this hardcodes the LAN IP into the deploy bundle, which
isn't portable across customer sites. Single-hostname is the recommended
path.

### App container restarting

```bash
docker compose logs --tail=200 perspectiv
```

The most common startup failure is a database connectivity issue. If
you see `psycopg2.OperationalError`, double-check `POSTGRES_PASSWORD`
in `.env` matches the password the postgres container was initialised
with. If they got out of sync, the fastest path is:

```bash
docker compose down -v              # ⚠️  DROPS ALL DATA
docker compose up -d                # fresh DB with current .env creds
```

For existing data you want to keep, `ALTER USER perspectiv_user WITH
PASSWORD '...'` inside the postgres container is the non-destructive
fix.

### Pool connection warnings

```
WARNING database.pg_pool — PG pool cap 100 exceeded
```

Expected on the largest deployments during dashboard traffic spikes.
If you see these consistently on a sized-down VM, bump memory by one
tier — the pool cap auto-scales with hardware but the Perspectiv
container is conservative by default.

---

## 7. Uninstall

```bash
# Stop and remove containers, networks, and all data (⚠️ destructive)
docker compose down -v

# Remove the deploy directory
cd .. && rm -rf perspectiv-deploy
```

---

## 8. Support

- **Documentation**: https://docs.perspectiv.net
- **Community**: https://support.perspectiv.net
- **Commercial support**: support@perspectiv.net
- **Status page**: https://status.perspectiv.net

Report bugs or feature requests via the support portal with your
deployment ID (Settings → About → Deployment ID) attached to the
ticket.
