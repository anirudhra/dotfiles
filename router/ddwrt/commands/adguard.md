# Configuration for AdGuard Home on DD-WRT

* ```opkg update && opkg install curl``` (to install curl)
* ```curl -s -S -L https://raw.githubusercontent.com/MomenMamdouh/AGH-for-DDWRT/main/AGH-Installer/installAGH.sh | sh -s -- -v```
  * Add --u or --r to the end of above command line to either uninstall or re-install adguard home 
* Go to "Setup > Dynamic Host Configuration Protocol (DHCP)" and untick "Use dnsmasq for DNS" and "Recursive DNS Resolving (Unbound)". Make sure that you have disabled any other DNS resolver you have enabled before, such as SmartDNS, etc.
* Add the following to dnsmasq additional options ("Services > Dnsmasq Infrastructure > Additional Options")
```
# Force order and pass DNS resolution to Adguard
strict-order
no-resolv
# Point all bridges to the Router's IP for DNS
# AdGuard Home will pick up the traffic on Port 53
dhcp-option=br0,6,<main-network-ip.1>
dhcp-option=br1,6,<guest1-netowrk-ip.1>
dhcp-option=br2,6,<guest2-network-ip.1>
dhcp-option=br3,6,<other-network-ip.1>
# Gateway Options
dhcp-option=br0,3,<main-network-ip.1>
dhcp-option=br1,3,<guest1-network-ip.1>
dhcp-option=br2,3,<guest2-network-ip.1>
dhcp-option=br3,3,<other-network-ip.1>
```
* Go to "Services > Dnsmasq Infrastructure" and disable "No DNS Rebind"
* Reboot your Router and open http://<ROUTER_IP>:3000 to open the Adguard Home setup page (make sure you set dns port #53, GUI can be anything other than 80/8080/443 as it conflicts with DD-WRT setup page. Choose 3000 to be safe)
* Some upstream servers to use:
``` 
tls://dns.quad9.net
https://dns.nextdns.io/e27b26
https://cloudflare-dns.com/dns-query
tls://unfiltered.adguard-dns.com
quic://unfiltered.adguard-dns.com
https://unfiltered.adguard-dns.com/dns-query
```
