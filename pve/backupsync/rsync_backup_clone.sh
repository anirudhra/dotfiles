#!/bin/sh
# script to use rsync for backups and cloning disks
# syntax: script.sh source/ destination/
# replicates all files inside source directory in destination directory. leading slash is required
rsync -avxHAXW --progress "$1" "$2"
