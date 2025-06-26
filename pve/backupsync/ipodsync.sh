#!/bin/sh
# (c) Anirudh Acharya 2024
# iPod Music and Playlists Sync script
# Run this script from PVE Server (not one of the LXCs or VMs)
# Only one iPod must be connected when the script is invoked
# Script will keep iPod in sync with the music and playlists on the Server/NAS
# This script expects certain paths/names/hostnames etc. to work correctly

# various server directories
server_basesourcedir="/mnt/sata-ssd/ssd-media/media/music"
source_musicdir="${server_basesourcedir}/music"
source_playlistsdir="${server_basesourcedir}/playlists"

# ipod directories/mounts/devices
#ipod5g_mountdir="/mnt/IPOD5G"
#ipod7g_mountdir="/mnt/IPOD7G"
ipod_mountdir="/mnt/ipod"
#ipod5g_device="/dev/sdb2" #FIXME: /dev/sdX2
#ipod7g_device="/dev/sdb1" #FIXME: /dev/sdX1
ipod_musicdir="${ipod_mountdir}/music"
ipod_playlistsdir="${ipod_mountdir}/playlists"

######################################################################3
# Check if iPod is attached
# FIXME: Fix this entire section later
#ipod7g_devid="05ac:1261"
#ipod5g_devid="05ac:1262" #FIXME

#if [[ $(lsusb | grep -i "$ipod7g_devid") && $(lsusb | grep -i "$ipod5g_devid") ]]; then
#    echo "Two iPods are detected! Only one iPod can be connected when this script is invoked, disconnect one and re-run script"
#    exit
#elif [[ $(lsusb | grep -i "$ipod7g_devid") ]]; then
#    echo "Found iPod 7G"
#elif [[ $(lsusb | grep -i "$ipod5g_devid") ]]; then
#    echo "Found iPod 5G"
#else
#    echo "No iPod found!"
#    exit
#fi
######################################################################3

######################################################################3
# unmount, create mount point (failsafe) and mount ipod
#umount $ipod_device
#mkdir -p "${ipod_mountdir}"
#mount ${ipod_device} ${ipod_mountdir}
#ls ${ipod_mountdir}

# manually mount instead of auto, too many corne cases for now
# ipod7g has /dev/sdX1 as the partition while ipod5g has /dev/sdX2 as the partition
echo
echo "==============================================================================="
echo "Ensure your iPod is mounted at ${ipod_mountdir} before running this script"
echo
echo "For iPod5G: mount /dev/sdX2 ${ipod_mountdir}"
echo "For iPod7G: mount /dev/sdX1 ${ipod_mountdir}"
echo "==============================================================================="
echo
echo "Contents of ${ipod_mountdir}:"
echo
ls ${ipod_mountdir}
echo
echo "==============================================================================="
echo "Disk space usage of ${ipod_mountdir}"
df -h ${ipod_mountdir}
echo
echo "==============================================================================="
echo
echo "Source music dir: ${source_musicdir}"
echo "Source playlist dir: ${source_playlistsdir}"
echo "Destination music dir:${ipod_musicdir}"
echo "Destination playlist dir:${ipod_playlistsdir}"
echo
echo "==========================================================================================="
echo "If this is not correct, press Ctrl+C to exit, mount and rerun. Else Press Enter to continue"
echo "==========================================================================================="

# read into dummy variable to pause
read answer

# create destination ipod directories, in case they don't exist
mkdir -p ${ipod_playlistsdir}
mkdir -p ${ipod_musicdir}

######################################################################3
# sync playlists and music with progress shown
echo "Syncing playlists..."
echo
# --size-only is for quick check, -c can be added for complete checksum instead (slower)
# Don't forget the leading "/" in front of source directories to specify copying the 
# contents of that dir and not the dir itself!
rsync -hvr --size-only --modify-window=2 --delete ${source_playlistsdir}/ ${ipod_playlistsdir}

echo
echo "Syncing music..."
echo
# sync music files
rsync -hvr --size-only --modify-window=2 --delete ${source_musicdir}/ ${ipod_musicdir}

######################################################################3
# done
echo
echo "==============================================================================="
echo " All done. Manually unmount iPod after verifying with the command: "
echo " umount ${ipod_mountdir}"
echo "==============================================================================="
echo

# end of script
