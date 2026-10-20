#!/bin/sh
#vzdump --all --exclude 100,101 --notification-mode notification-system --mode snapshot --remove 0 --compress zstd --node pve --storage sata-ssd --notes-template '{{guestname}}'
vzdump --all --notification-mode notification-system --mode snapshot --remove 0 --compress zstd --node pve --storage sata-ssd --notes-template '{{guestname}}'
