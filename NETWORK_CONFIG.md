# Network & API Configuration

System-X uses **`/etc/rysen/systemx-network.ini`** as the single source of truth for:

- Network identity (name, label, organisation URL)
- Central API URLs (talkgroups, bridges, server list)
- Verified-server status reporting (token broadcaster)

Dashboard **presentation** (logos, social links, marquee, footer credits) stays in:

```
/var/www/html/dashboard/config/
```

Custom **web assets** preserved on upgrade:

```
/var/www/html/index.html
/var/www/html/images/
/var/www/html/dashboard/img/
```

---

## Quick reference

| Setting | INI key | Used by |
|---------|---------|---------|
| Network display name | `[network] name` | Dashboard Info pages (wwtg, wwbridges, wwservers) |
| Network label | `[network] label` | Dashboard intro text |
| Organisation link | `[network] org_url` | Info menu (optional; also see branding.php) |
| Peer ID JSON | `[api] peer_json_url` | Upgrade JSON refresh, RYSEN |
| Subscriber ID JSON | `[api] subscriber_json_url` | Upgrade JSON refresh, RYSEN |
| Talkgroup JSON | `[api] tg_json_url` | Dashboard, JSON refresh |
| Talkgroup CSV | `[api] tg_csv_url` | Dashboard download links |
| Bridge JSON | `[api] bridge_json_url` | Dashboard wwbridges |
| Servers CSV | `[api] servers_csv_url` | Dashboard wwservers, JSON refresh |
| Status POST URL | `[api] status_api_url` | Token broadcaster (cron, every 5 min) |
| Status API secret | `[api] status_api_secret` | Token broadcaster |
| CSV header rows to skip | `[api] servers_csv_skip_lines` | wwservers page |
| Offline badge threshold (minutes) | `[api] server_stale_minutes` | Verified-server badges |

---

## File locations on the server

```
/etc/rysen/systemx-network.ini      ← Edit this for network/API settings
/etc/rysen/systemx-broadcaster.cfg  ← Auto-managed (HOSTNAME + API from INI)
/var/www/html/dashboard/config/     ← Branding, navbar, footer (preserved)
/etc/rysen/rysen.cfg                ← RYSEN container — keep URL keys aligned
/etc/rysen/fdmr-mon.cfg             ← Monitor container — keep URL keys aligned
```

---

## FreeSTAR authorized operators (default)

**No action required** for a standard FreeSTAR System-X deployment.

After install or upgrade:

1. `systemx-network.ini` is created automatically with FreeSTAR defaults.
2. Token status reporting to `api.freestar.network` works out of the box.
3. Dashboard Info pages (Talkgroups, Bridges, Verified Servers) use the FreeSTAR central API.

Verify token reporting:

```bash
sudo /usr/local/sbin/systemx-token-broadcaster
crontab -l | grep systemx-token-broadcaster
```

---

## Regional / coordinated network APIs

Some authorized operators run a **coordinated regional API** (hosted with FreeSTAR team approval) while remaining part of the System-X platform.

In that case:

1. Run **menu → Full System Upgrade** once (seeds INI if missing).
2. Edit `/etc/rysen/systemx-network.ini` with URLs provided by the FreeSTAR team.
3. Coordinate with FreeSTAR before changing `status_api_url` or `status_api_secret`.
4. Align `/etc/rysen/rysen.cfg` and `/etc/rysen/fdmr-mon.cfg` URL keys with the same endpoints.
5. **Do not change FreeSTAR dashboard branding** unless explicitly approved (see authorization criteria in [README.md](README.md)).

Contact **shane@freestar.network** before pointing at a non-FreeSTAR central API.

---

## Verified servers (global server list)

The dashboard **Verified Servers** page reads a central CSV and shows badge status per host.

### How it works

1. Each member server runs `systemx-token-broadcaster` every 5 minutes (cron).
2. Broadcaster POSTs to `status_api_url` (from network INI).
3. Central API updates `servers_csv_url`.
4. Dashboard **wwservers** displays Verified / Unauthorized / Pending / Offline.

### CSV format (`SystemX_Hosts.csv`)

```
Country, DMR-ID, Host, Password, Port, token_status, last_update_unix
```

Valid `token_status` values: `verified`, `unauthorized`, `pending`, `unknown`.

If you operate the central API host, install it with `api-install.sh` from the System-X-Installer repository and set `status_api_secret` in the INI to match.

---

## Upgrade behaviour

| Item | On upgrade |
|------|------------|
| `systemx-network.ini` | **Preserved** if present; seeded with FreeSTAR defaults if missing |
| `systemx-broadcaster.cfg` | HOSTNAME refreshed; API settings taken from INI when present |
| `/etc/rysen/json/*` | Refreshed from INI URLs only if missing or older than 7 days |
| `dashboard/config/` | **Fully preserved** (branding, navbar, footer) |
| `index.html`, `images/`, `dashboard/img/` | **Preserved** |

Existing FreeSTAR servers are **safe to upgrade once** — behaviour matches previous releases unless you have already customised the INI.

---

## Example INI (custom central API)

```ini
[network]
name = ExampleNet
label = Example DMR Network Europe
org_url = https://example.network/dmr

[api]
peer_json_url = https://radioid.net/static/rptrs.json
subscriber_json_url = https://radioid.net/static/users.json
tg_json_url = https://api.example.network/v1/talkgroup_ids.json
tg_csv_url = https://api.example.network/v1/talkgroup_ids.csv
bridge_json_url = https://api.example.network/v1/bridge_ids.json
servers_csv_url = https://api.example.network/v1/SystemX_Hosts.csv
status_api_url = https://api.example.network/v1/update-server-status.php
status_api_secret = your-secret-from-api-install
servers_csv_skip_lines = 2
server_stale_minutes = 10
```

Edit on the server:

```bash
sudo nano /etc/rysen/systemx-network.ini
```

Then verify dashboard Info pages and run a test broadcast:

```bash
sudo /usr/local/sbin/systemx-token-broadcaster
```

---

## Branding vs network configuration

| Allowed without FreeSTAR approval | Requires FreeSTAR approval |
|-----------------------------------|----------------------------|
| Editing `systemx-network.ini` API URLs when coordinated with the team | Removing or replacing FreeSTAR logos/branding |
| Social links in `navbar-custom.php` | Changing dashboard identity to non-FreeSTAR branding |
| Homepage tiles in preserved `index.html` / `images/` | Disabling verified-server reporting without coordination |

---

## Related documentation

- [DEPLOYMENT.md](DEPLOYMENT.md) — Full installation and upgrade guide
- [README.md](README.md) — Authorization criteria and getting started
- [CHANGELOG.md](CHANGELOG.md) — Release notes

---

**FreeSTAR System-X — Professional DMR Networking for Ham Radio**
