# Pricing

## Everything included. One product. Every tier.

No module-licensing math. No per-feature upsells. No surprise true-ups when you add devices.

Pick the size that fits your environment, not the features you're allowed to use.

---

## Plans

| Plan | Devices (full monitoring) | ICMP-only | Monthly | Annual (15% off) |
|---|---|---|---|---|
| **Starter** | 100 | unlimited | $349/mo | $3,560/yr ($297/mo) |
| **Professional** | 250 | unlimited | $749/mo | $7,640/yr ($637/mo) |
| **Business** | 500 | unlimited | $1,299/mo | $13,250/yr ($1,104/mo) |
| **Enterprise** | 1,000 | unlimited | $2,299/mo | $23,450/yr ($1,954/mo) |
| **Scale** | 1,000+ | unlimited | custom | custom |

> **Annual prepay locks in 15% off** across all named tiers. Multi-site, multi-tenant, and government pricing on the Scale tier — talk to us.

---

## Only pay for full monitoring

Every fully-monitored device — SNMP, WMI, agent — counts toward your plan's cap.

**ICMP-only devices are free.** Ping your entire network without limits, on any plan.

Discovered 800 devices on your subnet scan? Watch them all. Promote the ones that actually matter to full monitoring when you're ready.

---

## What's included in every plan

Every tier includes every feature. Choose your tier based on how many devices you need to monitor and the level of support you want — not on which monitoring capabilities you can unlock.

### Network & infrastructure
- **Network performance monitoring** — SNMP v1, v2c, v3 with per-interface metrics, traffic, errors, discards
- **Server & application monitoring** — CPU, memory, disk, processes, services via Perspectiv agent
- **NetFlow analysis** — top talkers, conversation flows, application breakdown
- **Configuration backup & change tracking** — daily snapshots, diff history, restore on demand
- **IP address management (IPAM)** — subnet utilization, conflict detection, address forecasting
- **Topology / network maps** — auto-discovered via LLDP/CDP, drag-to-edit overlays
- **Service checks** — TCP, HTTP/HTTPS, DNS, ICMP, traceroute (Netpath)

### Alerting & response
- **Multi-channel alerting** — email, webhooks, custom escalation paths
- **Per-rule cooldowns and dedup** — no 3am alert storms
- **Acknowledge & comment workflow** — incident hand-off across shifts
- **SNMP trap & syslog ingestion** — full-text searchable, alert-correlatable

### Reporting & dashboards
- **Custom dashboards** — drag-to-place widgets, per-user layouts, sharing
- **Pre-built reports** — availability, performance, lifecycle (EOL), backup status
- **Scheduled email reports** — daily, weekly, monthly digests to stakeholders
- **Historical retention** — 14 days raw / 1 year hourly / 5 years daily, on every plan

### Security & operations
- **Single sign-on (SSO)** — SAML, OIDC (included from Professional and up)
- **Role-based access control** — admin, operator, read-only, custom roles
- **Audit log** — every config change, who, when, what changed
- **System backup & restore** — full Perspectiv config in one click
- **Built-in SSH client** — to monitored devices, no second tool needed

---

## How Perspectiv compares to SolarWinds

| Feature | SolarWinds | Perspectiv |
|---|---|---|
| Network Performance Monitor (NPM) | NPM module | **Every plan** |
| Server & Application Monitor (SAM) | SAM module | **Every plan** |
| NetFlow Traffic Analyzer (NTA) | NTA module | **Every plan** |
| Network Configuration Manager (NCM) | NCM module | **Every plan** |
| IP Address Manager (IPAM) | IPAM module | **Every plan** |
| Database Performance (DPA) | DPA module | **Every plan** |
| Log management / syslog | LEM module | **Every plan** |
| Pricing model | Per-node, per-module | **Flat rate per tier** |
| ICMP-only devices count toward cap | Yes | **No, free on every plan** |
| Database engine | SQL Server (license $) | **TimescaleDB (free)** |
| Hosting | Windows physical / VM (167 GB+ RAM observed in production) | **Linux container (~16 GB RAM typical)** |
| Upgrade cadence | Quarterly, manual | **Continuous, scripted** |
| First-year all-in cost (500 devices) | ~$50,000 | **~$15,600** |

Numbers above are based on publicly listed SolarWinds pricing for a 500-node Hybrid Cloud Observability Essentials deployment plus typical SQL Server Enterprise + Windows licensing + dedicated server hardware sized to actual production SolarWinds RAM observations (167 GB peak on a real customer deployment). Your mileage may vary.

---

## Frequently asked questions

### How does the device limit actually work?

Your plan's cap applies to **fully-monitored devices** — those configured for SNMP, WMI, or Perspectiv agent. ICMP-only devices (basic reachability checks) don't count and are unlimited on every plan. When you're at the cap and try to add a fully-monitored device, Perspectiv offers two choices: add it as ICMP-only (free), or upgrade your plan. Existing devices keep being monitored regardless of cap state — no service interruption.

### Can I switch plans?

Yes, any time. Upgrade takes effect immediately. Downgrade takes effect at the next renewal so you're never penalized for trying a higher tier.

### Is there a free trial?

A 30-day fully-functional trial is included on every Perspectiv install. No credit card required to start. The trial is capped at 10 fully-monitored devices to give you a meaningful pilot scope.

### Do I need to install anything to get monitoring?

For SNMP-capable devices (switches, routers, firewalls, printers): no, just point Perspectiv at the device. For Windows / Linux / macOS hosts: install the Perspectiv agent on each host (one-line installer for Linux, MSI/wizard for Windows). The agent self-monitors and ships metrics back — no inbound ports needed on the monitored host.

### Self-hosted or cloud?

**Self-hosted.** You run Perspectiv on your own infrastructure (VM, Docker container, on-prem hardware — your choice). Your data stays with you. We don't host customer environments yet; if that's important, talk to us about Scale tier.

### What about HA, multi-site, distributed pollers?

Talk to us about the **Scale** tier. Single-host deployments handle up to 1,000 fully-monitored devices comfortably; multi-site distributed setups are custom-engineered.

### What's your upgrade story?

`docker compose pull && docker compose up -d`. That's it. No SQL Server upgrade rituals, no module compatibility matrices, no upgrade-weekend war rooms. We push patch releases continuously and roll them into customer-stable image tags.

### Do you charge for support?

No. Email support is included on every paid plan during business hours. Priority and 24/7 SLA-backed support is included on Business and Enterprise tiers respectively. We don't have a separate "support contract" SKU.

### Can I host this air-gapped?

Yes. Perspectiv runs entirely offline once licensed — license keys are Ed25519-signed and verify locally. No outbound calls home. Updates can be pulled from your internal mirror.

### How do I license multiple instances?

Each license key is bound to a single Perspectiv instance UUID at issuance. For multi-instance deployments (DR, dev/staging, multi-site), purchase additional licenses or contact us about Scale tier bundle pricing.

### What happens if I exceed my device cap?

The Devices page shows a soft warning at 80% and a clear over-cap banner at 100%. Existing monitoring keeps working. New full-monitoring adds get a dialog: "add as ICMP-only (free)" or "upgrade your plan." We don't break service mid-incident.

---

## Professional services

For teams that want hands-on help during deployment, migration, or ongoing operations, we offer scoped engagements at transparent rates — typically 30-50% below comparable SolarWinds professional services pricing.

| Package | What's included | Price |
|---|---|---|
| **Quick Start** | First-time setup, license activation, agent rollout, 1-hour guided walkthrough. Get producing same-day. | **$999** fixed |
| **Standard Implementation** | 16-hour engagement: full deployment, dashboard buildout, alert configuration, notification integration (Slack/PagerDuty/webhooks), 1-hour training session. | **$4,500** fixed |
| **SolarWinds Migration** | Port your existing device inventory, alert rules, and custom dashboards from SolarWinds. Includes Standard Implementation. 60-day side-by-side run with SolarWinds so you never lose visibility. | **$7,500** fixed |
| **Enterprise Implementation** | Multi-site, distributed pollers, custom integrations, advanced RBAC setup, 2-day on-site or remote training. Quoted per engagement. | from **$25,000** |
| **Training Workshop** | Half-day live training session for up to 10 attendees. Role-based curriculum (admins, operators, executives). | **$2,500** fixed |
| **Custom hourly** | Ad-hoc work — custom reports, one-off integrations, performance tuning, complex queries. | **$200/hour** |
| **Annual Success Retainer** | Ongoing relationship — 8 hours/month rolling, used for tuning, new use cases, escalation support. Cancel any time. | **$1,500/month** |

[Talk to sales](mailto:sales@perspectiv.net?subject=Professional%20Services%20enquiry) about scoping or to request a custom quote.

> **Charter customers** (first 10 customers + design partners): Quick Start and SolarWinds Migration are **complimentary** as part of the program. The investment in your success buys us reference relationships and a hardened migration playbook for everyone who follows.

---

## Ready to start?

**[Request a demo](mailto:sales@perspectiv.net?subject=Perspectiv%20demo%20request)** · 30-minute walkthrough on your environment.

**[Start a trial](https://downloads.perspectiv.net/latest/PerspectivAgentSetup.exe)** · Self-install, 30-day fully-functional, no credit card.

**[Contact sales](mailto:sales@perspectiv.net)** · Multi-site, government, education, regulated industries — we'll work with you.
