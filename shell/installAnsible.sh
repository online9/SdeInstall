#!/bin/bash
# ===============================================================
#  Create by BumJo Kim
#  Service Dept. Ssangyong Information & Communications Corp.
# ===============================================================

installMethod=""

askInstallByPip() {
    if [ "${installMethod}" == "" ]; then
        printf "Do you want to intall ansible by python pip? [yes]"; read installYn

        if [ "${installYn}" == "" -o "${installYn}" == "yes" -o "${installYn}" == "y" ]; then
            installMethod="pip"
        else
            installMethod="yum"
        fi
    fi
}

while [ $# -ne 0 ]; do
    arg="$1"
    case "${arg}" in
        --by-pip) installMethod="pip" ;;
        --by-yum) installMethod="yum" ;;
    esac
    shift
done

osVersion=`cat /etc/*-release | grep VERSION_ID | awk -F "=" '{ print $2 }' | tr -d '"'`
osRelease=`cat /etc/*-release | grep PRETTY_NAME | awk -F "=" '{ print $2 }' | tr -d '"' | tr '[A-Z]' '[a-z]'`

echo "System OS Release info : "`cat /etc/*-release | grep PRETTY_NAME | awk -F "=" '{ print $2 }'`
echo "Ansible Install Method : ${installMethod}"

if [[ ${osRelease} =~ ubuntu ]]; then
    askInstallByPip

    if [ "${installMethod}" == "pip" ]; then
        sudo -S apt install -y python3-pip python3-jmespath
        pip3 install --upgrade pip
        pip install ansible
    else
        sudo -S apt install -y ansible
    fi
elif [[ ${osRelease} =~ centos ]]; then
    askInstallByPip

    if [ "${installMethod}" == "pip" ]; then
        sudo yum update -y
        sudo yum install -y python3-pip sshpass python-passlib
        pip3 install --upgrade pip
        pip install jmespath
        pip install ansible
    else
        sudo yum update -y
        sudo yum install -y epel-release
        sudo yum install -y ansible sshpass
    fi
elif [[ ${osRelease} =~ redhat ]]; then
    sudo yum update -y
    sudo yum install -y python3-pip sshpass python-passlib

    pip3 install --upgrade pip
    pip install jmespath
    pip install ansible
elif [[ ${osRelease} =~ oracle ]]; then
    sudo yum update -y
    sudo yum install -y python3-pip sshpass
    pip install jmespath
else
    echo "Unknown Linux Release ....."
    exit
fi

if [[ ${osRelease} =~ ubuntu ]]; then
    source ~/.bashrc
    source ~/.profile
fi

mkdir -p /etc/ansible

if [ ! -e /etc/ansible/ansible.cfg ]; then
    cp /sde/cloud/ansible/config/ansible.cfg /etc/ansible
fi

sed -i "/host_key_checking/c\host_key_checking = False" /etc/ansible/ansible.cfg
sed -i "/deprecation_warnings/c\deprecation_warnings = False" /etc/ansible/ansible.cfg

ansible --version

