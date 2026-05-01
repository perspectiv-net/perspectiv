# Perspectiv Quickstart

**Get Perspectiv monitoring your network in about 10 minutes.**

This is the short path to a running Perspectiv instance and your first monitored device. For deeper deployment topics (TLS certs, multi-site, backup automation, upgrade procedures), see [DEPLOY.md](../deploy/DEPLOY.md).

---

## Before you start

You'll need:

- **A Linux host** with Docker + Docker Compose plugin (or Docker Desktop on macOS / Windows for testing)
- **16 GB RAM minimum, 50 GB disk** — Perspectiv is light, but TimescaleDB likes headroom
- **Network access** from the host to whatever devices you want to monitor (SNMP/UDP, ICMP, etc.)
- **A web browser** to access the dashboard
- **Your user added to the `docker` group** — see prereq check below; missing this is the #1 cause of "permission denied" on fresh Ubuntu installs

### Prereq sanity check (Ubuntu / Debian, fresh install)

Run this once on your host. **Note:** Ubuntu's default repos ship `docker.io` but **not** `docker-compose-plugin` — that lives only in Docker's own apt repo. We add Docker's repo and install everything from there for a consistent setup.

```bash
# 1. Add Docker's official apt repo
sudo apt-get update
sudo apt-get install -y ca-certificates curl
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
    -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo $VERSION_CODENAME) stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# 2. Install Docker Engine + Compose plugin from Docker's repo
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io \
    docker-buildx-plugin docker-compose-plugin

# 3. Add YOUR user to the docker group (so you don't need sudo for every docker command)
sudo usermod -aG docker $USER
```

> **Don't mix `docker.io` (Ubuntu) with `docker-compose-plugin` (Docker's repo).** The Ubuntu-packaged `docker.io` works, but only Docker's own repo has the modern `docker compose` v2 plugin. If you previously ran `apt install docker.io`, run `sudo apt-get remove docker.io` before the steps above to avoid two parallel docker installs.

**Important:** `usermod` only updates `/etc/group` on disk. Your **current** SSH session still has the old group list loaded from login time. You must refresh group membership before docker commands will work:

```bash
# EITHER (quick, current shell):
newgrp docker

# OR (most reliable, recommended on a fresh VM):
exit
# then SSH back in
```

After re-login, smoke-test:

```bash
groups               # docker should appear in the list
docker version       # should print Docker daemon info, no permission error
docker compose version
```

If `docker version` still shows `permission denied while trying to connect to the docker API at unix:///var/run/docker.sock` after re-login, something else is off — usually means `usermod` didn't take effect (typo on $USER, perhaps) or the docker daemon isn't running (`sudo systemctl status docker`).

About 10 minutes of your time. No license required to start — Perspectiv self-activates a 30-day trial on first launch (capped at 10 fully-monitored devices, unlimited ICMP-only devices).

---

## Step 1 — Get the deployment bundle

Clone the repo or download the deploy folder:

```bash
git clone https://github.com/perspectiv-net/perspectiv.git
cd perspectiv
```

That gets you `docker-compose.yml`, `traefik/`, `scripts/`, `.env.example`, and the `docs/` folder with the operator-grade `DEPLOY.md` reference.

---

## Step 2 — Configure secrets

Copy the example template and fill in the required values:

```bash
cp .env.example .env
$EDITOR .env
```

The variables you must set: `POSTGRES_PASSWORD`, `LETSENCRYPT_EMAIL`, and (for production) `PERSPECTIV_HOSTNAME`. The `.env.example` walks through every variable with an explanation. For a lab test, the only thing that's strictly required is `POSTGRES_PASSWORD` — `PERSPECTIV_HOSTNAME` defaults to `perspectiv.local` and `LETSENCRYPT_EMAIL` accepts any value when ACME can't issue a real cert.

If you want to generate the file inline rather than editing the template, here's the equivalent heredoc:

```bash
cat > .env <<EOF
# Postgres credentials — pick a strong password, store it somewhere safe
POSTGRES_USER=perspectiv_user
POSTGRES_PASSWORD=$(openssl rand -base64 32 | tr -d '/+=')
POSTGRES_DB=perspectiv

# Perspectiv image tag — pin to a customer-stable release
PERSPECTIV_VERSION=0.4.7

# Hostname Traefik routes by — PERSPECTIV_HOSTNAME is REQUIRED (Traefik
# matches the Host header to this exact value; visiting via raw IP
# returns Traefik's default 404 page). For lab testing, leave as
# perspectiv.local and add a hosts file entry on your workstation.
# For production, set this to your real DNS name.
PERSPECTIV_HOSTNAME=perspectiv.local

# Email used by Let's Encrypt for cert-expiry notices. REQUIRED
# (docker-compose refuses to start Traefik without it). For lab
# testing on perspectiv.local, ACME can't actually issue a cert (the
# .local hostname isn't publicly resolvable), so the value is stored
# but unused — you can put any address here. For production with a
# real DNS hostname, use a monitored mailbox so you see the
# "your cert expires in 14 days" warning if renewal ever stalls.
LETSENCRYPT_EMAIL=admin@example.com
EOF
```

### Make the hostname resolvable from your browser

Traefik routes by `Host` header, so your browser must request `https://perspectiv.local` (or whatever you set), not the VM's raw IP. Two options:

**Lab testing (most common)** — add a hosts file entry on the **workstation running your browser** (not the Perspectiv VM):

- **Linux/macOS:** `sudo $EDITOR /etc/hosts`
- **Windows:** edit `C:\Windows\System32\drivers\etc\hosts` (Notepad as Administrator)

Add:
```
<VM-ip>   perspectiv.local
```

(Replace `<VM-ip>` with the actual IP of the host running Perspectiv.)

**Production** — point a real DNS A record at the host's IP and set `PERSPECTIV_HOSTNAME` to that real DNS name. See [DEPLOY.md](../deploy/DEPLOY.md) for the Let's Encrypt TLS setup that makes this seamless.

---

## Step 3 — Start the stack

```bash
docker compose up -d
```

You'll see three containers come up: `perspectiv-postgres` (TimescaleDB), `perspectiv-traefik` (reverse proxy + TLS), `perspectiv-app` (Perspectiv itself).

Watch the app start — should take ~10-15 seconds:

```bash
docker logs -f perspectiv-app
```

Wait for `[100%] Ready.` then Ctrl-C out.

---

## Step 4 — Open the dashboard

Browse to:

```
https://<your-host>     (or https://perspectiv.local if you used the default)
```

Your browser will warn about the self-signed cert. Click through.

You'll land on the **bootstrap admin** page — set up your first user. Username and password get stored in the database; you can add more users later via Settings → Users.

---

## Step 5 — Activate the trial

After login, navigate to **Settings → License**. The trial activates with one click — no key required, no credit card. You get:

- 30 days
- 10 fully-monitored devices (SNMP, WMI, agent)
- Unlimited ICMP-only devices
- All features enabled (no module gating)

Need more capacity for a serious evaluation? See [Step 8](#step-8--need-a-bigger-trial-) below.

---

## Step 6 — Add your first device

### Option A: SNMP-capable device (switch, router, firewall, printer)

1. Go to **Devices → Add Device**
2. Enter:
   - Name (whatever you want)
   - IP address
   - Protocol: **SNMP** (or **SNMP v3** if you've set that up)
   - Community string (default `public` works for most kit out of the box for read-only)
3. Click Save

Within ~60 seconds you'll see metrics on the device's detail page (CPU, memory, interfaces, response time).

### Option B: Linux/Windows server (run the Perspectiv agent on it)

1. Go to **Settings → Agents → Add Agent**
2. Enter:
   - Name (e.g. "DC-Server-01")
   - Site name
   - Check **"Auto-register host as a device"** (default — recommended)
3. Click Create. **Copy the API key.**
4. On the target host:
   - **Linux:** download `install-agent-linux.sh` from `https://downloads.perspectiv.net/latest/install-agent-linux.sh`, then run `sudo ./install-agent-linux.sh --server https://your-perspectiv-host --api-key <copied-key>`
   - **Windows:** download `https://downloads.perspectiv.net/latest/PerspectivAgentSetup.exe`, double-click, follow the wizard. Paste the same server URL and API key when prompted.
5. The agent's first heartbeat (within 60 seconds) auto-creates the device row and starts streaming metrics.

---

## Step 7 — Explore

You're now monitoring. Suggested next clicks:

- **Dashboards → My Dashboards** — drag-to-place widgets, build whatever you want
- **Reports → Performance / Availability / Lifecycle** — pre-built reports, scheduled email digests
- **Settings → Alerts → Rules** — set up your first alert (CPU > 90%, etc.)
- **Tools → SSH** — built-in SSH client to managed devices

---

## Step 8 — Need a bigger trial?

Hitting the 10-device cap or the 30-day expiry? **As a charter customer / design partner, you can request an extended trial license at any time** (typically 250 devices for 90 days while you evaluate).

To request:

1. Go to **Settings → License** in your Perspectiv dashboard
2. Note your **Instance ID** (a UUID near the bottom of the page)
3. Email **[sales@perspectiv.net](mailto:sales@perspectiv.net?subject=Extended%20trial%20request)** with:
   - Subject: `Extended trial request`
   - Your Instance ID
   - How many devices you want to test (rough estimate)
   - How long you'd like — 30, 60, or 90 days

You'll get a `PERSP-v2-...` key back, usually same-day. Paste it into Settings → License → Activate.

---

## Need help?

- **Docs**: [github.com/perspectiv-net/perspectiv/blob/main/deploy/DEPLOY.md](https://github.com/perspectiv-net/perspectiv/blob/main/deploy/DEPLOY.md) — operator-grade deployment reference
- **Issues / questions**: email [sales@perspectiv.net](mailto:sales@perspectiv.net) — direct line, founder-answered for now
- **Migrating from SolarWinds?** Charter customers get free migration assistance — let us know in the same email

Welcome to Perspectiv.
