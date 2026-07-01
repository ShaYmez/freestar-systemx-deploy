# System-X 1.5.0 Release Roadmap — Motorola IPSC Selfcare

**Target release:** 1.5.0 (July 2026)  
**Operator impact:** Significant — new Docker service, RYSEN backend, config stanzas, firewall port  
**MMDVM-only sites:** Can upgrade safely; IPSC remains disabled until explicitly enabled

---

## Executive summary

System-X **1.5.0** adds **Motorola IPSC repeater** support alongside existing MMDVM hotspot selfcare:

| Traffic | Path | Container |
|---------|------|-----------|
| MMDVM hotspot | UDP 62031 | `proxy` (`shaymez/rysen-sp-selfcare`) |
| IPSC repeater CPS | UDP **56002** | `ipsc-proxy` (`shaymez/rysen-sp-ipsc`) |
| TS1/TS2 apply | MariaDB `Clients` mode=0 | `systemx` (RYSEN master) |
| Dashboard / login | Apache + PHP | Host `/var/www/html/dashboard` |

This release coordinates **six repositories** and **five Docker images**. Do not tag installer **1.5.0** until satellite images are published with IPSC support merged to `master`.

---

## Repository map (source of truth)

```
RYSEN (ipsc → master)          Core: ipsc_master.py, bridge_master options poll, ipsc_proxy.py
    ├── merge ──► RYSEN-SP-SELFCARE    proxy_db.py (mode > 0 filter), hotspot_proxy_v2.py
    │                  └──► shaymez/rysen-sp-selfcare:latest   (proxy :62031)
    ├── split ──► RYSEN-SP-IPSC        ipsc_proxy.py
    │                  └──► shaymez/rysen-sp-ipsc:latest        (ipsc-proxy :56002)
    └── build ──► shaymez/rysen:latest                            (systemx)

RYSEN-MONITOR                  PHP/JS selfcare UI, monitor.py IPSC peers, WebSocket opcodes 2–5
    └──► shaymez/rysen-monitor:latest                             (monitor :9000)

System-X-Installer (this repo) Templates, compose, upgrade merge, Apache dashboard bundle
freestar-systemx-deploy        Token deploy wrapper (no IPSC-specific changes expected)
```

| Repo | Branch / action | Deliverable |
|------|-----------------|-------------|
| **RYSEN** | Merge `ipsc` → `master` | IPSC register, selfcare options poll, `ipsc_proxy.py` |
| **RYSEN-SP-SELFCARE** | Sync `proxy_db.py` from RYSEN | `AND mode > 0` in `slct_db` (no RPTO for IPSC rows) |
| **RYSEN-SP-IPSC** | Sync from RYSEN | `shaymez/rysen-sp-ipsc:latest` |
| **RYSEN-MONITOR** | `master` (synced to installer) | Dashboard + monitor backend |
| **System-X-Installer** | Tag `v1.5.0` | Compose, configs, additive upgrade merge |
| **freestar-systemx-deploy** | Bump version refs | Deploy menu points at 1.5.0 docs |

---

## What 1.5.0 ships in System-X-Installer

### Docker stack (`docker-compose-user.yml`)

| Service | Image | IP | Ports |
|---------|-------|-----|-------|
| `systemx` | `shaymez/rysen:latest` | .10 | 62034–62050/udp, 4321/tcp, 52555/udp |
| `mariadb` | `lscr.io/linuxserver/mariadb:latest` | .11 | 8306→3306 |
| `monitor` | `shaymez/rysen-monitor:latest` | **.12** (was .30) | 9000 |
| `proxy` | `shaymez/rysen-sp-selfcare:latest` | .20 | 62031/udp |
| `ipsc-proxy` | `shaymez/rysen-sp-ipsc:latest` | .30 | **56002/udp** |
| `d-aprs` | `shaymez/rysen-d-aprs:latest` | .40 | 8080 |

**Startup order:** mariadb → rysen → ipsc-proxy → proxy → monitor → d-aprs

### Configuration files

| File | Purpose |
|------|---------|
| `rysen.cfg` | `[IPSC]` stanza (disabled by default), `[SELF SERVICE]` (disabled by default) |
| `ipsc-proxy.cfg` | UDP forwarder to RYSEN IPSC master slots |
| `proxy-selfcare.cfg` | Unchanged — MMDVM hotspot selfcare |
| `fdmr-mon.cfg` | PHP selfcare DB + monitor connection |
| `systemx-network.ini` | API URLs (unchanged contract) |

### Upgrade behaviour (new in 1.5.0)

- **Additive config merge** — missing sections/keys appended from bundle; live values never overwritten
- **No `.new` sidecar files** — stale `*.new` removed on upgrade
- **Compose** — full template apply with password/APRS env preservation
- **rules.py** — never overwritten (site-specific)

Existing servers upgrading from 1.4.x automatically gain `[IPSC]`, `[SELF SERVICE]` in `rysen.cfg`, and `ipsc-proxy.cfg`, when absent.

---

## Pre-release checklist (maintainers)

### 1. RYSEN (`ipsc` → `master`)

- [ ] `ipsc_master.py` — IPSC register, `Clients` mode=0 upsert (preserve password on re-register)
- [ ] `bridge_master.py` / options poll — `(SELF SERVICE) Applied options for IPSC …`
- [ ] `[SELF SERVICE]` stanza support in `rysen.cfg`
- [ ] CI green on IPSC tests
- [ ] Publish **`shaymez/rysen:latest`** with IPSC build

### 2. RYSEN-SP-SELFCARE

- [ ] `proxy_db.py` → `slct_db` includes `AND mode > 0`
- [ ] Publish **`shaymez/rysen-sp-selfcare:latest`**

### 3. RYSEN-SP-IPSC

- [ ] `ipsc_proxy.py` synced from RYSEN
- [ ] Publish **`shaymez/rysen-sp-ipsc:latest`**

### 4. RYSEN-MONITOR

- [ ] `html/` synced into installer (`scripts/sync-rysen-monitor-html.sh --check`)
- [ ] IPSC peer display on Linked Systems (opcodes 2–5 in `monitor.js`)
- [ ] Publish **`shaymez/rysen-monitor:latest`** if backend changed

### 5. System-X-Installer

- [ ] CI passes (`tests/run_ci_tests.sh`)
- [ ] Tag **`v1.5.0`**
- [ ] Verify upgrade dry-run on staging VM (`systemx-upgrade-dryrun`)

### 6. freestar-systemx-deploy

- [ ] Version strings / help text reference 1.5.0
- [ ] No breaking deploy-script changes required (installer carries compose)

---

## Production rollout (operators)

### A. All sites (MMDVM + IPSC)

1. **Backup** — upgrade creates smart backup automatically; confirm `/opt/backups/`
2. **Upgrade installer** — menu → Upgrade, or `systemx-upgrade`
3. **Pull images** — `cd /etc/rysen && docker compose pull`
4. **Restart stack** — `systemx-restart` (sequential startup includes ipsc-proxy)
5. **Verify** — dashboard loads, MMDVM selfcare login still works
6. **Passwords** — change defaults if not already done (`freestar3`)

### B. IPSC-enabled sites (additional steps)

1. **Enable in `rysen.cfg`:**
   ```ini
   [IPSC]
   ENABLED: True
   # Set IPSC_MASTER_ID, AUTH_KEY, static TS1/TS2 as required

   [SELF SERVICE]
   ENABLED: True
   DB_PASS: <match mariadb/fdmr-mon.cfg>
   ```
2. **Firewall** — allow UDP **56002** from repeater public IPs
3. **Repeater CPS** — Master UDP port **56002** → server public IP
4. **Commission** — `sudo selfcare-admin` → register repeater / set password
5. **Test selfcare** — login with callsign or radio ID → change TS2 → confirm RYSEN log within ~5s
6. **Confirm proxy** — hotspot proxy logs show **no** RPTO for IPSC `dmr_id`

### C. MMDVM-only sites

- No action after upgrade — `[IPSC] ENABLED: False` leaves IPSC inactive
- `ipsc-proxy` container runs but accepts no traffic until repeaters connect
- Optional: leave disabled; no CPS traffic on 56002

---

## Architecture (runtime)

```
Repeater CPS ──UDP 56002──► ipsc-proxy ──► RYSEN [IPSC] master (:56003+)
                                    │
Hotspot ──UDP 62031──► proxy (selfcare) ──► Clients mode>0 ──RPTO──► hotspot

PHP selfcare ──► MariaDB Clients (modified=1)
                      │
                      ├── mode=0 ──poll──► RYSEN master (TS1/TS2 static apply)
                      └── mode>0 ──poll──► proxy (MMDVM options string)
```

Static talkgroups for IPSC are applied **on the server** — the repeater does not receive a Homebrew options packet.

---

## Database (no migration)

| `Clients.mode` | Meaning |
|----------------|---------|
| `0` | IPSC repeater (RYSEN writes on register) |
| `4` | MMDVM simplex hotspot (proxy) |
| other `> 0` | MMDVM duplex hotspot (proxy) |

No `ALTER TABLE` on production MariaDB.

---

## Validation matrix

| Test | Expected |
|------|----------|
| `bash scripts/sync-rysen-monitor-html.sh --check` | Pass (dashboard in sync) |
| `systemx-upgrade-dryrun` | Shows `[MERGE]` for missing IPSC stanzas on 1.4.x hosts |
| Repeater connects | Linked Systems shows IPSC badge, TS1/TS2 activity |
| Selfcare TS2 change | `(SELF SERVICE) Applied options for IPSC <id>` in systemx logs |
| MMDVM hotspot save | RPTO still sent; unchanged behaviour |
| `systemx-check-updates` | Lists `shaymez/rysen-sp-ipsc:latest` |

---

## Rollback

1. `systemx-rollback` — restores pre-upgrade backup (configs + compose)
2. Or pin images to pre-1.5.0 digests in `docker-compose.yml` and `docker compose up -d`

---

## Documentation index

| Doc | Audience |
|-----|----------|
| [RELEASE_1.5.0_ROADMAP.md](RELEASE_1.5.0_ROADMAP.md) | Maintainers / release coordination (this file) |
| [IPSC_SELFCARE.md](IPSC_SELFCARE.md) | Operators — selfcare behaviour and admin CLI |
| [DEPLOYMENT.md](DEPLOYMENT.md) | Full install/upgrade guide |
| [NETWORK_CONFIG.md](NETWORK_CONFIG.md) | API URL alignment |

---

## Version history

| Version | IPSC |
|---------|------|
| 1.4.x | MMDVM selfcare only |
| **1.5.0** | IPSC repeater selfcare + ipsc-proxy stack |

---

**Copyright (C) 2020-2026 Shane Daley M0VUB** — System-X / FreeSTAR Network
