# IPSC repeater selfcare (operators)

Motorola IPSC repeater static talkgroup (TS1/TS2) selfcare for System-X **1.5.0+**. MMDVM hotspot selfcare is unchanged.

Full release coordination (satellite repos, images, checklists): **[RELEASE_1.5.0_ROADMAP.md](RELEASE_1.5.0_ROADMAP.md)**

Upstream detail: [RYSEN-MONITOR doc/ipsc-selfcare-roadmap.md](https://github.com/ShaYmez/RYSEN-MONITOR/blob/master/doc/ipsc-selfcare-roadmap.md)

---

## Quick reference

| Item | Value |
|------|-------|
| Repeater CPS Master UDP | **56002** (public IP of server) |
| Hotspot selfcare UDP | 62031 (unchanged) |
| Admin CLI | `sudo selfcare-admin` |
| Enable IPSC | `rysen.cfg` → `[IPSC] ENABLED: True` + `[SELF SERVICE] ENABLED: True` |
| DB row type | `Clients.mode = 0` |

---

## Login behaviour

- **MMDVM:** callsign + password (`mode > 0` only)
- **IPSC:** callsign **or** all-digit radio ID + password; session routes by logged-in row `mode` (`0` = IPSC)
- **First-time claim:** empty password + online IPSC row → set password on login

---

## Enabling IPSC on an existing server

1. Upgrade to **1.5.0** (config merge adds stanzas automatically)
2. Edit `/etc/rysen/rysen.cfg` — set `[IPSC] ENABLED: True`, configure master ID / auth key
3. Set `[SELF SERVICE] ENABLED: True` and matching DB password
4. `cd /etc/rysen && docker compose pull && systemx-restart`
5. Open firewall UDP 56002
6. `sudo selfcare-admin` — register repeater or reset password for first-time claim
7. Point repeater CPS at server:56002

---

## Admin tools

Install once (included in 1.5.0 install/upgrade):

```bash
sudo selfcare-admin
```

Menu: list IPSC repeaters, set/change password, reset (enables claim), pre-register.

Uses PBKDF2-SHA256 (`salt=RYSEN`, 2000 rounds) — same hash as PHP selfcare.

---

## Troubleshooting

| Symptom | Check |
|---------|-------|
| Repeater won't connect | Firewall UDP 56002; `docker logs ipsc-proxy`; `MASTER` in `ipsc-proxy.cfg` = 172.16.238.10 |
| No IPSC row in dashboard | RYSEN ipsc build running; repeater registered on master |
| TS2 change has no effect | `[SELF SERVICE] ENABLED: True`; RYSEN logs; MariaDB `Clients.modified=1` |
| Hotspot broken after IPSC | Pull latest `rysen-sp-selfcare` (mode > 0 filter) |

See [RELEASE_1.5.0_ROADMAP.md](RELEASE_1.5.0_ROADMAP.md) for the full validation matrix.
