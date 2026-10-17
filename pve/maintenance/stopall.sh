#!/bin/bash

VM_LIST=/tmp/list_VM.list
CT_LIST=/tmp/list_CT.list

# We catch the VM & CT from each server
qm list | awk 'NR>1{ print $1 }' > $VM_LIST
pct list | awk 'NR>1{ print $1 }' > $CT_LIST

mapfile -t listvm < $VM_LIST

for i in ${listvm[@]};
  do
    echo "VM $i will be shutdown..."
    qm shutdown $i
    echo "VM $i has been shutdown"
    echo ""
  done

#echo ""

mapfile -t listct < $CT_LIST

for i in ${listct[@]};
  do
    echo "CT $i will be shutdown..."
    pct shutdown $i
    echo "CT $i has been shutdown"
    echo ""
  done

#echo ""

#echo "We set the noout flag on CEPH Cluster:"
#ceph osd set noout

#echo "We now can safely shutdown the server"
#shutdown -h now

rm $VM_LIST
rm $CT_LIST
echo "Cleaned up temp. VM/CT lists. End of script. PVE Server can be safely shutdown."

