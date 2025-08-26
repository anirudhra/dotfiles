# Add under admin > commands > startup

* mount --bind should be skipped typically as it is not a good idea to have /jffs on external USB (mounted at /opt). Any failure will take down the router with it
* Creation of ~/.vimrc can also be skipped and added to the persistent /opt/root/.profile or better yet the canonical dotfiles' .profile.<hostname> instead

```
# entware initialization
sleep 10
/opt/etc/init.d/rc.unslung start
#
# to overlay USB over internal /jffs (not recommended)
# mount --bind /opt/jffs /jffs
#
# for sourcing aliases, stored on USB's /opt/root/dotfiles dir 
cat <<'EOF' >"/tmp/root/.ashrc"
source /opt/root/.profile
EOF
#
# to stop vim from complaining about defaults.vim file
cat <<'EOF' >"/tmp/root/.vimrc"
set nu
set wrap
EOF
```
