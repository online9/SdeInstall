#!/bin/bash

# ===============================================================
#  Create by BumJo Kim
#  Service Dept. Ssangyong Information & Communications Corp.
# ===============================================================

getValue() {
    echo "$1" | awk -F"=" '{ print $2 }'
}

replaceOrAppend() {
    file=$1
    id=$2
    value=$3

    if [ "${value}" != "" ]; then
        exist=`cat ${file} | grep ${id}`

        if [ "${exist}" != "" ]; then
            echo "Change `cat ${file} | grep ${id}` => ${id}=${value}"
            sed -i "/${id}=/c${id}=${value}" ${file}
        else
            echo "Append ${id}=${value} to ${file}"
            echo "${id}=${value}" >> ${file}
        fi
    fi
}

changeNicSettings() {
    if [ "${eth}" == "" ]; then
        eth="eth0"
    fi

    ethFile="/etc/sysconfig/network-scripts/ifcfg-${eth}"

    replaceOrAppend "${ethFile}" "ONBOOT" "yes"
    replaceOrAppend "${ethFile}" "IPADDR" "${hostIp}"
    replaceOrAppend "${ethFile}" "UUID" "`uuidgen`"
    replaceOrAppend "${ethFile}" "GATEWAY" "${gateway}"
    replaceOrAppend "${ethFile}" "NETMASK" "${netmask}"
    replaceOrAppend "${ethFile}" "DNS1" "${dns1}"
    replaceOrAppend "${ethFile}" "DNS2" "${dns2}"
    replaceOrAppend "${ethFile}" "MTU" "${mtu}"
}

changeNicSettings4Ubuntu() {
    if [ "${eth}" == "" ]; then
        eth="eth0"
    fi

    netplanPath="/etc/netplan"
    isExistYq=`which yq`

    # yq is a yaml parser
    if [ "${isExistYq}" == "" ]; then
        sudo snap install yq
    fi

    case "${osVersion}" in
          18.04 ) ethFile="50-cloud-init.yaml" ;;
          20.04 ) ethFile="00-installer-config.yaml" ;;
          21.04 ) ethFile="00-installer-config.yaml" ;;
    esac

    echo "sudo cp ${netplanPath}/${ethFile} /home/${user}/${ethFile}"
    sudo cp ${netplanPath}/${ethFile} /home/${user}/${ethFile}
    ls -al /home/${user}/${ethFile}

    echo "value=\"$hostIp/$prefix\" yq eval --inplace '.network.ethernets.eth0.addresses = [env(value)]' /home/${user}/${ethFile}"
    sudo value="$hostIp/$prefix" yq eval --inplace '.network.ethernets.eth0.addresses = [env(value)]' /home/${user}/${ethFile}

    echo "value=\"$gateway\" yq eval --inplace '.network.ethernets.eth0.gateway4 = env(value)' /home/${user}/${ethFile}"
    sudo value="$gateway" yq eval --inplace '.network.ethernets.eth0.gateway4 = env(value)' /home/${user}/${ethFile}

    if [ "${mtu}" != "" ]; then
        echo "value=\"$mtu\" yq eval --inplace '.network.ethernets.eth0.mtu = env(value)' /home/${user}/${ethFile}"
        sudo value="$mtu" yq eval --inplace '.network.ethernets.eth0.mtu = env(value)' /home/${user}/${ethFile}
    fi

    if [ "${dns}" != "" ]; then
        echo "value=\"$dns\" yq eval --inplace '.network.ethernets.eth0.nameservers.addresses = [env(value)]' /home/${user}/${ethFile}"
        sudo value="$dns" yq eval --inplace '.network.ethernets.eth0.nameservers.addresses = [env(value)]' /home/${user}/${ethFile}
    fi

    if [ "${searchDomain}" != "" ]; then
        echo "value=\"$searchDomain\" yq eval --inplace '.network.ethernets.eth0.nameservers.search = [env(value)]' /home/${user}/${ethFile}"
        sudo value="$searchDomain" yq eval --inplace '.network.ethernets.eth0.nameservers.search = [env(value)]' /home/${user}/${ethFile}
    fi

    echo "sudo mv /home/${user}/${ethFile} ${netplanPath}/${ethFile}"
    sudo mv /home/${user}/${ethFile} ${netplanPath}/${ethFile}
    ethFile="${netplanPath}/${ethFile}"
}

user=`echo $LOGNAME`
osVersion=`cat /etc/*-release | grep VERSION_ID | awk -F "=" '{ print $2 }' | tr -d '"'`
osRelease=`cat /etc/*-release | grep PRETTY_NAME | awk -F "=" '{ print $2 }' | awk '{ print $1 }' | tr -d '"' | tr '[A-Z]' '[a-z]'`

sudoExec=""

if [ "${user}" != "root" ]; then
    sudoExec="sudo -S "
fi

while [ $# -ne 0 ]; do
    arg="$1"
    case "${arg}" in
        --eth=*) ethName=`getValue "$1"` ;;
        --host=*) hostName=`getValue "$1"` ;;
        --ip=*) hostIp=`getValue "$1"` ;;
        --gw=*) gateway=`getValue "$1"` ;;
        --netmask=*) netmask=`getValue "$1"` ;;
        --prefix=*) prefix=`getValue "$1"` ;;
        --dns=*) dns=`getValue "$1"` ;;
        --dns1=*) dns1=`getValue "$1"` ;;
        --dns2=*) dns2=`getValue "$1"` ;;
        --mtu=*) mtu=`getValue "$1"` ;;
        --search=*) searchDomain=`getValue "$1"` ;;
    esac
    shift
done

echo "Operation Id   : ${user}"
echo "Os Information : ${osRelease} ${osVersion}"


if [ "${osRelease}" == "ubuntu" ]; then
    isDash=`ls -al /bin/sh | grep dash`

fi

echo "Setting Information" > ~/resetHost-result.txt
echo "Change Host Name `hostname` => ${hostName}"
${sudoExec} hostnamectl set-hostname ${hostName}


if [ "${osRelease}" == "ubuntu" ]; then
    changeNicSettings4Ubuntu
else
    changeNicSettings
fi

if [ "${osRelease}" != "ubuntu" -a "${searchDomain}" != "" ]; then
    echo "Append Search Domain `cat /etc/resolv.conf | grep search` => ${searchDomain}"

        sudo chattr -i /etc/resolv.conf

    exist=`cat /etc/resolv.conf | grep search | awk -v name="${searchDomain}" '{if ($1 == "search" && $2 == name) { print "YES" } else { print "NO" }  }'`

    if [ "${exist}" == "YES" ]; then
        echo "Already exist search ${searchDomain} in /etc/resolv.conf ..... SKIP"
    else
        echo "Append search ${searchDomain} to /etc/resolv.conf"
        sudo echo "search ${searchDomain}" >> /etc/resolv.conf
    fi

    sudo chattr +i /etc/resolv.conf
fi

echo " "
echo "Nic Setting Information : "`hostname`
echo "------------------------------------------------------------"
echo "${eth} : ${ethFile}"
cat ${ethFile}
echo " "
echo "Search Domain Information : "
echo "------------------------------------------------------------"
cat /etc/resolv.conf

sync
