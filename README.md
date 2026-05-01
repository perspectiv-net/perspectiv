# Perspectiv

**Self-hosted network monitoring for small and mid-market IT teams.**

Perspectiv is a network monitoring platform you run on your own infrastructure. It combines SNMP, NetFlow, syslog, and ICMP polling with installable Windows and Linux agents to give your team a full picture of network device health, performance, and availability — without per-node licensing or runaway costs.

This repository contains the **deploy bundle and public documentation**. The Perspectiv application itself is distributed as a Docker image at `ghcr.io/perspectiv-net/perspectiv`.

---

## Quick start

You'll need:

- A Linux host with Docker + Docker Compose (Ubuntu 22.04+ or similar)
- 16 GB RAM, 50 GB disk minimum
- ~10 minutes

```bash
git clone https://github.com/perspectiv-net/perspectiv.git
cd perspectiv

# Configure your environment
cp .env.example .env
$EDITOR .env       # set PERSPECTIV_HOSTNAME, POSTGRES_PASSWORD, LETSENCRYPT_EMAIL

# Bring up the stack
docker compose up -d
docker compose logs -f perspectiv
```

When you see `[100%] Ready.` in the logs, browse to `https://<your-hostname>` and create your first admin user.

For the full, paste-friendly walkthrough — including DNS setup, the Ubuntu Docker repo install path, and lab-vs-production guidance — see [`docs/quickstart.md`](docs/quickstart.md).

---

## What's in this repo

| Path | What it is |
|---|---|
| `docker-compose.yml` | Production-ready Docker Compose stack: Perspectiv, PostgreSQL/TimescaleDB, Traefik (reverse proxy + auto-TLS) |
| `traefik/` | Traefik static + dynamic config (TLS termination, security headers, ACME) |
| `scripts/` | Operational scripts: `backup.sh`, `restore.sh`, `upgrade.sh` |
| `.env.example` | Template for required environment variables |
| `docs/quickstart.md` | 10-minute install walkthrough |
| `docs/DEPLOY.md` | Operator-grade deployment reference: TLS internals, multi-site, backup automation, upgrade procedures |
| `LICENSE` | Apache 2.0 — applies to the deploy bundle and docs only (see "License" below) |

---

## Trial license

First-boot launches a 30-day trial automatically. The trial includes:

- 30 days from activation
- Up to 10 fully-monitored devices (SNMP, WMI, agent)
- Unlimited ICMP-only devices
- All features enabled

Need a longer evaluation period or higher device cap for a serious pilot? Contact [sales@perspectiv.net](mailto:sales@perspectiv.net) — we routinely issue 90-day extended trials for charter customers and design partners.

Pricing and tier details: [https://perspectiv.net/pricing](https://perspectiv.net/pricing)

---

## Documentation

- [Quickstart](docs/quickstart.md) — first install, end-to-end
- [Deployment reference](docs/DEPLOY.md) — TLS, backups, upgrades, multi-site
- [Design Partner Program](docs/design-partner-program.md) — extended trial + commercial pilot details
- Full product docs at [https://perspectiv.net/docs](https://perspectiv.net/docs)

---

## Issues / feedback

Found a bug in the deploy bundle? Have a question about a configuration option? File an issue here — public issue tracker, we triage daily.

For product-level questions (pricing, license keys, feature requests, security disclosures): email [sales@perspectiv.net](mailto:sales@perspectiv.net).

For migration assistance from SolarWinds, PRTG, Zabbix, or LibreNMS — charter customers receive complimentary migration support; mention your existing platform when you reach out.

---

## License

The contents of **this repository** (deploy bundle, scripts, public docs) are licensed under the [Apache License 2.0](LICENSE). Modify them freely for your environment, redistribute them, fork them — standard permissive open-source terms.

The **Perspectiv application image** (`ghcr.io/perspectiv-net/perspectiv`) is **proprietary commercial software** governed by the Perspectiv End User License Agreement. Customers must hold a valid license key to operate the software. Free 30-day trial is automatic on first boot.

In other words: the launcher is open; the engine isn't.

---

## About

Perspectiv is built by [Perspectiv LLC](https://perspectiv.net). We're a small, focused team building network monitoring software that small and mid-market IT teams actually want to use — predictable pricing, quick install, no per-node billing, no surprise feature gates.

Website: [https://perspectiv.net](https://perspectiv.net)
Docs:    [https://perspectiv.net/docs](https://perspectiv.net/docs)
Sales:   [sales@perspectiv.net](mailto:sales@perspectiv.net)
