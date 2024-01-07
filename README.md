# HA-HTTPS-TailScale
Secure acces to your HA using HTTPS with valid TailScale certificates.

## Issues:
- When trying to implement HTTPS using valid certificates using TailScale many different problems appears, so I need to put all the solution together in order to remember how to do it again.
- Assume you have a TailScale account with at least 2 hosts configured (and 1 is the HAServer)
- Assume you have "Advanced SSH & Web Terminal" installed in your HAServer

## TailScale basic installation:
- Install "TailScale with features" addon from @lmagyar. Please follow the instructions and relax, it's the only easy part in all the process :)

https://github.com/lmagyar/homeassistant-addon-tailscale/
- Start TailScale, and select "Open WebUI"
- Log in your TailScale account

## TailScale crazy config:
- HA Home page -> Config -> AddOns -> "TailScale with features" -> Configuration -> Options
- Activate "Show extra configuration options not used"
- Activate "Userspace networking mode"
- Save
- Restart
- Deactivate "Userspace networking mode"
- Save
- Restart

I know it sounds crazy, I know it has no sense but it works, so shut up, stop complaining and follow the howto.

## TailScale basic test
Open your admin interface:

https://login.tailscale.com/admin/machines

And write down some hostnames (including the domain tail#####.ts.net with it's ips.

> ha-server.tail01234.ts.net -> 100.1.2.3
>
> laptop.tail01234.ts.net -> 100.3.2.1

Open a terminal in your ha-server and try to ping laptop.tail01234.ts.net and 100.1.2.3, usually you would be able to ping the ip but not the fqdn (laptop.tail01234.ts.net). That's because the TailScale DNS is not being used for the system. If it's your case, follow up with "HA Basic DNS config" if everything is working jump the section.

## HA Basic dns config:
- HA Home page -> Config -> System -> Network

Usually you will any interface under the "Configure network interfaces" section, but if you have some you usally need to configurre enp0s3 ... usually ... so click on enp0s3
- Click on IPV4 -> Select Static

Under the "DNS Server" field write down 100.100.100.100,1.1.1.1 -> What we are doing with this is setting the TailScale DNS (the one that is able to resolv laptop.tail01234.ts.net) as the first DNS of our HA and 1.1.1.1 (which is an easy public one) as secondary. You can use your ISP DNS instead of 1.1.1.1

Please repeat the basic test and be sure that all the pings are working.

## Generate .cert and .pem files for HTTPS
- Download MakeHttpsHeadersFromTailScale.sh , and execute it in your HAServer -> Restart the HAServer, all the HAServer!
- Or if you feel like having control of what's going on:
>
>docker ps -> you can get the CONTAINER_ID
>
> docker exec -it CONTAINER_ID /bin/bash
>
>  echo "nameserver 1.1.1.1">>/etc/resolv.conf
>
>  cd;/opt/tailscale cert HA_NAME.tailYOUR_NUM.ts.net
>
>  -rw-r--r-- 1 root root 5274 Dec 16 10:04 HA_NAME.tailYOUR_NUM.ts.net.crt
>
>  -rw------- 1 root root  227 Dec 16 10:04 HA_NAME.tailYOUR_NUM.ts.net.key
>
>  exit
>
>docker cp CONTAINER_ID:/root/HA_NAME.tailYOUR_NUM.ts.net.crt HA_NAME.tailYOUR_NUM.ts.net.crt
>
>docker cp CONTAINER_ID:/root/HA_NAME.tailYOUR_NUM.ts.net.key HA_NAME.tailYOUR_NUM.ts.net.key
>
>openssl pkcs8 -topk8 -nocrypt -in HA_NAME.tailYOUR_NUM.ts.net.key -out HA_NAME.tailYOUR_NUM.ts.net.pem
>
>rm HA_NAME.tailYOUR_NUM.ts.net.key
>
>mkdir /config/certs
>
>mv HA_NAME.tailYOUR_NUM.ts.net.crt /config/certs/HA_NAME.tailYOUR_NUM.ts.net.crt
>
>mv HA_NAME.tailYOUR_NUM.ts.net.pem /config/certs/HA_NAME.tailYOUR_NUM.ts.net.pem
>

configuration.yaml:

>http:
>
>  ssl_certificate: /config/certs/HA_NAME.tailYOUR_NUM.ts.net.crt
>
>  ssl_key: /config/certs/HA_NAME.tailYOUR_NUM.ts.net.pem
>


>restart
