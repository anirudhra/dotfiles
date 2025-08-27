# Installing entware on USB drive

* Format the drive as ext2 filesystem (avoid ext3/4 as the journaling feature can reduce the lifespan of USB flash drives, those are more suited to USB HDDs)
* Label the filesystem as "Optware" so that DD-WRT automounts it to /opt directory
* For armv7/h targets, run:

```
cd /opt
wget http://bin.entware.net/armv7sf-k3.2/installer/generic.sh
sh generic.sh
```

* For arm64 targets, run:

```
cd /opt
wget http://bin.entware.net/aarch64-k3.10/installer/generic.sh
sh generic.sh
```

* Update package list after installation and upgrade packages (if any):

```
opkg update && opkg upgrade
```

* Add the following lines to Administration > Commands > Startup script:

```
sleep 10
/opt/etc/init.d/rc.unslung start
```

* Moving to https version instead of http: https://github.com/Entware/Entware/wiki/Using-HTTPS-with-opkg

NOTE1: if you get nslookup: can't resolve 'bin.entware.net' then most likely your /etc/resolv.conf file has only a local nameserver entry (nameserver 192.168.1.1). Edit your /etc/resolv.conf file and add "nameserver 8.8.8.8"" save the file, and repeat the wget command above.

NOTE2: There is no need to add /opt/bin and /opt/sbin to PATH. DD-WRT automatically does it.

* Useful entware packages to install:
```
ncdu
git
git-http
tmux
iperf3
zoxide
eza
vim
lsof
cfdisk
atop
iftop
mc
unzip
unrar
nmap
tree
iptraf-ng
bzip2
wget-ssl
ca-certificates
```
* Btop should already be installed. Else, manually download armv7/arm64 version of btop from and place in /opt/sbin: https://github.com/aristocratos/btop/releases
* iotop, usbutils, pciutils don't seem to work

Reference: <https://wiki.dd-wrt.com/wiki/index.php/Installing_Entware>
