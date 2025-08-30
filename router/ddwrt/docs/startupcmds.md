# Add under admin > commands > startup

* mount --bind should be skipped typically as it is not a good idea to have /jffs on external USB (mounted at /opt). Any failure will take down the router with it
* Below assumes dotfiles is on /jffs (persistent emmc internal storage)

```
# entware initialization
sleep 10
/opt/etc/init.d/rc.unslung start
#
# smartdns adblock script: https://github.com/egc112/ddwrt/tree/main/adblock/smartdns
/jffs/ddwrt-adblock-s.sh &
# create login shell init script, sync dotfiles repo first
cat <<'EOF' >"/tmp/root/.ashrc"
source /jffs/dotfiles/home/.profile.ddwrt
EOF
```
