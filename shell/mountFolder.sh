#!/bin/bash
# ===============================================================
#  Create by BumJo Kim
#  Service Dept. Ssangyong Information & Communications Corp.
# ===============================================================

nfsServerInfo=$1
mountFolder=$2

if [ $# -lt 2 ]; then
    echo "mountFolder.sh <nfsServerInfo> <mountFolder>"
    echo "mountFolder.sh 172.17.0.2:/cloud /sde/cloud"
    exit
fi

isExist=`cat /etc/fstab | grep "${mountFolder}" | awk -v folder="${mountFolder}" '{ if ($2 == folder) { print "Y" } else { print "N" }}'`

if [ "${isExist}" == "Y" ]; then
    echo "Already exist mount point in /etc/fstab"
    exit
fi

isExist=`rpm -qa nfs-utils`

if [ "${isExist}" == "" ]; then
    yum install -y nfs-utils
fi

mkdir -p /bde/cloud
echo "${nfsServerInfo}  ${mountFolder}   nfs   defaults   0 0" >> /etc/fstab
mount ${mountFolder}

df -h