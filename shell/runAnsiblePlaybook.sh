#!/bin/bash
# ===============================================================
#  Create by BumJo Kim
#  Service Dept. Ssangyong Information & Communications Corp.
# ===============================================================

getValue() {
    key="$1"
    value=`echo "$2" | sed "s/--${key}=//g"`
    echo "${value}"
}

showVersion() {
    echo "ansible-playbook execute shell"
}

verbose=""

while [ $# -ne 0 ]; do
    arg="$1"
    case "${arg}" in
        --user*) user=`getValue "user" "${arg}"` ;;
        --path*) ansiblePath=`getValue "path" "${arg}"` ;;
        --inventory*) inventoryFile=`getValue "inventory" "${arg}"` ;;
        --playbook*) playbookPathAndFile=`getValue "playbook" "${arg}"` ;;
        --options*) options=`getValue "options" "${arg}"` ;;
        --verbose*) verbose="-"`getValue "verbose" "${arg}"` ;;
        --version) showVersion ;;
    esac
    shift
done

if [ "${inventoryFile}" == "" ]; then
    inventoryFile="sde-support.inv"
fi

if [ "${playbookPathAndFile}" == "" ]; then
    playbookPathAndFile="sdeEnv/main.yml"
fi

if [ "${user}" == "" ]; then
    user="root"
fi

if [ "${ansiblePath}" == "" ]; then
    ansiblePath="/sde/cloud/ansible"
fi

if [ "${options}" == "" ]; then
    options="targetServers=all"
fi

options="${options} ansiblePath=${ansiblePath}"
options=`echo ${options} | sed "s/:/ /g"`
options=`echo ${options} | sed "s/~/,/g"`

cd ${ansiblePath}

echo "Ansible Playbook execute configuration"
echo "======================================================================="
echo "Operation User                        : ${user}"
echo "-----------------------------------------------------------------------"
echo "Ansible Inventory File                : ${ansiblePath}/hosts/${inventoryFile}"
echo "Ansible Playbook File                 : ${ansiblePath}/playbook/${playbookPathAndFile}"
echo "Ansible Playbook Options              : ${options}"
echo "-----------------------------------------------------------------------"
echo "Ansible Folder                        : ${ansiblePath}"
echo "Current Folder                        : "`pwd`
echo "-----------------------------------------------------------------------"
echo ""

echo "Execute Cmd : ansible-playbook ${verbose} -i ${ansiblePath}/hosts/${inventoryFile} ${ansiblePath}/playbook/${playbookPathAndFile} -e '${options}' -f 32 -k -u ${user}"
ansible-playbook ${verbose} -i ${ansiblePath}/hosts/${inventoryFile} ${ansiblePath}/playbook/${playbookPathAndFile} -e "${options}" -f 32 -k -u ${user}
