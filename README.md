# Guiderails

Guiderails is a wrapper to DNSMASQ that blacklists everything and then selectively whitelists specific servers for a fully controlled and curated internet experience. The typical use case is to enable online education for young kids by blocking ALL internet sites, except for a dozen or two sites manually added by parents/teachers for a safer online experience.

## Basic idea

1. Guiderails starts it's own auxillary DNSMASQ based DNS service on your router (e.g. `192.168.1.1`) - just on another free but fixed IP address (e.g. `192.168.1.2`). See the section below for details on the auxillary IP address for more information.
2. You set the kids devices to use this auxillary DNS server. e.g. Log into your router Web UI -> LAN -> DNSFilter -> `Custom (user-defined) DNS 1` = `192.168.1.2` -> Apply -> Then select kids mac address -> Filtering mode = `Custom 1`

> NOTE: Guiderails is designed for Asus-WRT routers running [Merlin's](https://www.asuswrt-merlin.net/) custom linux firmware. Stock routers are typically limited, so this won't work

### Guiderails auxillary IP address

Guiderails starts it's own auxillary DNSMASQ based DNS service on your router (e.g. `192.168.1.1`) - just on another free but fixed IP address (e.g. `192.168.1.2`). So if your router is at `192.168.1.1` on the `br0` interface, Guiderails can come up at `192.168.1.2` on `br0:guiderails`. 

> NOTE: You must ensure the router's DHCP service doesn't give this IP address to other clients, so increase the DHCP start as needed. To do so, log into your router Web UI -> LAN -> DHCP -> IP Pool Starting Address. You can also change this later in the `/opt/share/guiderails/guiderails.conf` file under the `listen-address=192.168.1.2` setting.

## Installation

- ssh into the router
- run `curl -sO https://raw.githubusercontent.com/SidShetye/guiderails/wip/sid/install-guiderails.sh | sh install-guiderails.sh`
- done!

## Adding to the whitelist

- ssh into the router
- `nano /opt/share/guiderails/guiderails.conf` and add/replace the domains as you deem fit on the top
- `service restart_dnsmasq` to reload your changes

## Troubleshooting

### Manual installation

If you want to manually install, follow these instructions

- ssh into the router
- `mkdir /opt/share/guiderails/` for a location that persists reboots on Merlin firmware with Entware
- Download the `guiderails.sh` and `guiderails.conf` files to that location
- Edit the `guiderails.conf` file to set any whitelist domains you want (all on the on the top).
- Edit the `guiderails.conf` file to change `listen-address=192.168.1.2` to a suitable IP address. It should be a unique IP address so you might want to change your DHCP servers start address to begin *after* this.
- We need to start guiderails automatically, so create (or edit) `/jffs/scripts/dnsmasq.postconf` to have something like
```
#!/bin/sh
. /opt/share/guiderails/guiderails.sh restart
```
- `chmod a+x /jffs/scripts/dnsmasq.postconf` to make it executable
- test by the `service restart_dnsmasq` command

## Uninstallation

- ssh into the router
- stop by `/opt/share/guiderails/guiderails.sh stop`
- delete Guiderails by `rm -rf /opt/share/guiderails/*`
- `nano /jffs/scripts/dnsmasq.postconf` and remove the `. /opt/share/guiderails/guiderails.sh restart` line

## Manually starting/restarting?

Typically the script starts/restart automatically when the router boots up or when settings change. But if you want to manually run the script, log into the router via SSH and issue `/opt/share/guiderails/guiderails.sh [start/stop/restart]`

### Issues?

You are free to file an issue but note that I did this purely to learn the state of custom routers and the ability to add 3rd party services to them. It's something I did in my free time while also helping my kids be safe online. I would encourage you to try to fix the issue yourself or ask on [SNBForums](https://www.snbforums.com/forums/asuswrt-merlin.42/).

### Enhancements?

Web UI for the whitelists? Or some other idea? Please, fork this and go for it!
