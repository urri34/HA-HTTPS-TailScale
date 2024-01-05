# HA-HTTPS-TailScale
Secure acces to your HA using HTTPS with valid TailScale certificates.

## Issues:
- When trying to implement HTTPS using valid certificates using TailScale many different problems appears, so I need to put all the solution together in order to remember how to do it again.
- Assume you have a TailScale account with at least 2 hosts configured (and 1 is the ha server)
- Assume you have "Advanced SSH & Web Terminal" installed in your ha-server

## TailScale basic installation:
- Install "TailScale with features" addon from @lmagyar. Please follow the instructions and relax, it's the only easy part in all the process :)

https://github.com/lmagyar/homeassistant-addon-tailscale/

## TailScale crazy config:
- HA Home page -> Config -> AddOns -> "TailScale with features" -> Configuration
- Activate extra button
- Activate LAN
- Restart
- Deactivate LAN
- Restart

I know it sounds crazy, I know it has no sense but it works, so shut up and follow the howto.

## TailScale basic test
Open your admin interface:

https://login.tailscale.com/admin/machines

And get some hostnames (including the domain tail#####.ts.net with it's ips

> ha-server.tail01234.ts.net 100.1.2.3
>
> laptop.tail01234.ts.net 100.3.2.1

Open a terminal in your ha-server and try to ping laptop.tail01234.ts.net and 100.1.2.3, usually you would be able to ping the ip but not the fqdn (laptop.tail01234.ts.net). That's because the TailScale DNS is not being used for the system.

## HA Basic dns config:
