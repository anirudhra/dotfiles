# Configs for Smart DNS and dnsmasq

## SmartDNS

* Enable Resolver: Enabled 
* DualStack IP Selection: Disabled 
* Prefetch Domain: Enabled 
* Served Expired: Enabled 
* Use Additional Servers Only: Enabled 


```
# custom smartdns.conf file can be /jffs/etc, but not on USB due to boot reasons
# log-file is /tmp/smartdns.log
server 8.8.8.8 -bootstrap-dns
server 8.8.8.8 -group time -exclude-default-group
nameserver /pool.ntp.org/time
nameserver /time.google.com/time
nameserver /cloudflare-dns.com/time
server-tls 9.9.9.9:853 -host-name dns.quad9.net
server-tls 1.0.0.1:853 -host-name cloudflare-dns.com
server-tls 116.202.176.26:853 -host-name dot.libredns.gr
server-https https://1.1.1.1/dns-query
server-https https://9.9.9.9/dns-query
```

## dnsmasq 

* Enable dnsmasq and No DNS Rebind: Enabled 
* Rest: Disabled 

* Additional Options:
```
# current time needed for secure DNS, dnsmasq handles local dns while smartdns provides upstream dns
server=/pool.ntp.org/time.google.com/9.9.9.9
server=/pool.ntp.org/time.google.com/1.0.0.1
# dns rewrite wildcard for reverse proxy
address=/.<<ddns_domain>>/<<npm_ip_address>>
address=/<<ddns_domain>>/<<npm_ip_address>>
```
