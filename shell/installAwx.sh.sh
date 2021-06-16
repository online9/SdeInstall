#!/bin/bash
# ===============================================================
#  Create by BumJo Kim
#  Service Dept. Ssangyong Information & Communications Corp.
# ===============================================================



if [[ ${osRelease} =~ ubuntu ]]; then
elif [[ ${osRelease} =~ centos ]]; then
    if [[ ${osversion} =~ 7 ]]; then
        yum -y install docker git conntrack python3-pip
    elif [[ ${osversion} =~ 8 ]]; then
        yum -y install yum-utils git conntrack
        yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo
        yum -y install docker-ce
    fi

    systemctl enable docker
    systemctl start docker

    pip3 install --upgrade pip
    pip3 install docker-compose --ignore-installed
elif [[ ${osRelease} =~ redhat ]]; then
elif [[ ${osRelease} =~ oracle ]]; then
else
    echo "Unknown Linux Release ....."
    exit
fi

mkdir -p /sde
cd /sde
git clone -b 17.1.0 https://github.com/ansible/awx.git
cd /sde/awx/installer
sed -i "s/# admin_password/admin_password/g" inventory
ansible-playbook -i inventory install.yml