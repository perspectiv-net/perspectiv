# Perspectiv — Deployment Guide

This guide walks through deploying Perspectiv on a single Linux host
using the official Docker images. The resulting stack is a complete
network monitoring platform with TLS, automatic certificate renewal,
and built-in backups.

---

## 1. Prerequisites

### Hardware sizing

Match your expected fleet size to one of the following tiers. Larger
fleets should use the split-tier deployment pattern (separate Perspectiv
and PostgreSQL hosts) — contact support for guidance.

| Tier | Devices | vCPUs | RAM | Disk | Notes |
|------|---------|-------|-----|------|-------|
| **Small** | Up to 500 | 2 | 8 GB | 100 GB SSD | Evaluation / small office |
| **Medium** | Up to 2,000 | 4 | 16 GB | 200 GB SSD | Typical SMB deployment |
| **Large** | 2,000 – 5,000 | 8 | 32 GB | 500 GB SSD | Split-tier recommended |

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
# 1. Clone the deployment repo
git clone https://github.com/perspectiv-net/perspectiv-deploy.git
cd perspectiv-deploy

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

Default login on a fresh install:

```
Username:  admin
Password:  admin123
```

Change this immediately via Settings → Users.

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
