#!/bin/bash
# ===============================================================
#  Create by BumJo Kim
#  Service Dept. Ssangyong Information & Communications Corp.
# ===============================================================

ansibleFolder=$1

if [ "${ansibleFolder}" == "" ]; then
    ansibleFolder="/sde/cloud/ansible"
fi

mkdir -p ${ansibleFolder}/roles
cd ${ansibleFolder}/roles
ansible-galaxy collection install awx.awx
ansible-galaxy collection install community.general
ansible-galaxy collection install community.mysql
ansible-galaxy collection install community.grafana
ansible-galaxy collection install community.postgresql

ansible-galaxy install geerlingguy.awx -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.docker -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.ansible -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.repo-epel -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.pip -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.apache -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.nodejs -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.git -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.gitlab -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.svn -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.java -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.jenkins -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.mysql -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.postgresql -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.ruby -p /sde/cloud/ansible/roles
ansible-galaxy install dockpack.base_utils -p /sde/cloud/ansible/roles
ansible-galaxy install lrk.sonarqube -p /sde/cloud/ansible/roles
ansible-galaxy install lean_delivery.jenkins -p /sde/cloud/ansible/roles
ansible-galaxy install alvistack.svn -p /sde/cloud/ansible/roles
ansible-galaxy install ansible-thoteam.nexus3-oss -p /sde/cloud/ansible/roles
ansible-galaxy install alvistack.influxdb -p /sde/cloud/ansible/roles
ansible-galaxy install cloudalchemy.grafana -p /sde/cloud/ansible/roles
ansible-galaxy install idr.redmine_tracker -p /sde/cloud/ansible/roles
ansible-galaxy install vdzhorov.gerrit -p /sde/cloud/ansible/roles
ansible-galaxy install mrlesmithjr.gerrit -p /sde/cloud/ansible/roles
ansible-galaxy install robertdebock.subversion -p /sde/cloud/ansible/roles
ansible-galaxy install trombik.cyrus_sasl -p /sde/cloud/ansible/roles
ansible-galaxy install mrlesmithjr.apache2 -p /sde/cloud/ansible/roles
ansible-galaxy install bngsudheer.centos_base -p /sde/cloud/ansible/roles
ansible-galaxy install bngsudheer.ruby -p /sde/cloud/ansible/roles
ansible-galaxy install bngsudheer.redmine -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.elasticsearch -p /sde/cloud/ansible/roles
ansible-galaxy install geerlingguy.kibana -p /sde/cloud/ansible/roles

#ansible-galaxy install mesaguy.prometheus -p /sde/cloud/ansible/roles
#ansible-galaxy install inkatze.wildfly -p /sde/cloud/ansible/roles
#ansible-galaxy install lean_delivery.weblogic -p /sde/cloud/ansible/roles
#ansible-galaxy install evrardjp.keepalived -p /sde/cloud/ansible/roles
#ansible-galaxy install oefenweb.keepalived -p /sde/cloud/ansible/roles
#ansible-galaxy install darkwizard242.unzip -p /sde/cloud/ansible/roles
#ansible-galaxy install ondrejhome.ha-cluster-pacemaker -p /sde/cloud/ansible/roles
#ansible-galaxy install alvistack.etcd -p /sde/cloud/ansible/roles
#ansible-galaxy install geerlingguy.kubernetes -p /sde/cloud/ansible/roles
#ansible-galaxy install geerlingguy.aws-inspector -p /sde/cloud/ansible/roles
#ansible-galaxy install geerlingguy.haproxy -p /sde/cloud/ansible/roles
#ansible-galaxy install geerlingguy.logstash -p /sde/cloud/ansible/roles
#ansible-galaxy install geerlingguy.nginx -p /sde/cloud/ansible/roles
#ansible-galaxy install geerlingguy.redis -p /sde/cloud/ansible/roles
#ansible-galaxy install geerlingguy.rabbitmq -p /sde/cloud/ansible/roles
#ansible-galaxy install alvistack.gitlab_ce -p /sde/cloud/ansible/roles

ls -al

echo "Append additional utils(epel-release, nmon, unzip, nfs-tools) to dockpack.base_utils"
cp ${ansibleFolder}/config/dockpack.base_utils-main.yml ${ansibleFolder}/roles/dockpack.base_utils/defaults/main.yml
cp ${ansibleFolder}/config/lrk.sonarqube-sonar.service.j2 ${ansibleFolder}/roles/lrk.sonarqube/templates/sonar.service.j2
sed -i "s/awx_version: devel/awx_version: 17.0.1/g" ${ansibleFolder}/roles/geerlingguy.awx/defaults/main.yml
