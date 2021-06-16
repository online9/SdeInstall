param ($serverIp, $user="root", $basePath="/sde", $baseDrive="C:",
       $options="", $passwordless="", $nfsServerInfo="", $verbose="",
       $skipAll="no", $skipAnsible="no", $skipAnsibleFiles="no", $skipAnsibleRoles="no", $mountSdeFolder="no")

$cloudPath = "${basePath}/cloud"
$ansiblePath = "${cloudPath}/ansible"
$shellPath = "${cloudPath}/shell"
$localShellPath = "${baseDrive}${shellPath}".Replace("/", "\")
$hypervPowerShellPath = "${baseDrive}${cloudPath}/hyperv".Replace("/", "\")

Function Read-HostDefault($prompt, $default) {
    $prompt = "$prompt [$default]"
    $val = Read-Host $prompt
    ($default,$val)[[bool]$val]
}

Function Show-Help() {
    Write-Host 'NAME'
    Write-Host '    Install-Sde-Env'
    Write-Host ''
    Write-Host 'SYNOPSIS'
    Write-Host '    Install Support Development Environment(SDE)'
    Write-Host ''
    Write-Host 'SYNTAX'
    Write-Host '    installSdeEnv.ps1 -serverIp <AnsibleServerIp> [-user <User> -baseDrive <DriveLetter> -basePath <BasePath> -options <AnsiblePlaybook Extra Options>'
    Write-Host '                      -passwordless <*yes | no> -skipAnsible <yes | *no> -skipAnsibleFiles <yes | *no> -skipAnsibleRoles <yes | *no> -mountSdeFolder <yes | *no>]'
    Write-Host '    * AnsiblePlaybook Extra Options SYNTAX'
    Write-Host '      -options --key1=value1,--key2=value2'
    Write-Host ''
    Write-Host 'DESCRIPTION'
    Write-Host '    This is a PowerShell script that installs the SDE Support Server needed for Development project.'
    Write-Host '    Install Ansible, SCM(svn/git/gitlab), CI/CD(Jenkins), Static Analysis(SonarQube based on PostgreSQL),'
    Write-Host '    Repository(Maven,Nuget,npm,rpm...), and InfluxDB/Grafana Monitoring Servers'
    Write-Host '      1. Install Ansible Server first.'
    Write-Host '      2. Donwloads ansible roles via Ansible Galaxy'
    Write-Host '      3. Install SDE servers using ansible playbook SdeEnv.yml file'
    Write-Host '         - In the /sde/cloud/ansible/hosts/sde-support.inv file, describe the target server IP and server type and install it.'
    Write-Host '         - Examples /sde/cloud/ansible/hosts/sde-support.inv'
    Write-Host '           #------------------------------------------------------------------------------------------------'
    Write-Host '           #Ansible Host Sde-Support'
    Write-Host '            '
    Write-Host '           [all:vars]'
    Write-Host '           svn_http_port=80'
    Write-Host '           jenkins_http_port=8080'
    Write-Host '           nexus_http_port=8081'
    Write-Host '           sonarqube_http_port=9001'
    Write-Host '           grafana_http_port=3000'
    Write-Host '           ansible_ssh-common-args="-o strictHostKeyChecking=no"'
    Write-Host '           '
    Write-Host '           [all:children]'
    Write-Host '           SdeSupport'
    Write-Host '            '
    Write-Host '           [SdeSupport]'
    Write-Host '           Sde-Awx ansible_host=172.18.0.1 install_jdk=yes install_repo_epel=yes install_ansible=yes install_git=yes install_pip=yes install_nodejs=yes install_docker=yes server_type=ansible server_name=awx'
    Write-Host '           Sde-Scm ansible_host=172.18.0.2 install_jdk=yes server_type=scm server_name=svn'
    Write-Host '           Sde-CiCd ansible_host=172.18.0.3 install_jdk=yes server_type=ci server_name=jenkins'
    Write-Host '           Sde-Sonar ansible_host=172.18.0.4 install_jdk=yes server_type=analysis server_name=sonarqube'
    Write-Host '           Sde-Repo ansible_host=172.18.0.5 install_jdk=yes server_type=repository server_name=nexus'
    Write-Host '           Sde-Monitoring ansible_host=172.18.0.6 server_type=monitoring server_name=grafana'
    Write-Host '           #------------------------------------------------------------------------------------------------'
    Write-Host ''
    Write-Host 'Examples'
    Write-Host '    installSdeEnv.ps1 -help'
    Write-Host '    installSdeEnv.ps1 -serverIp 172.18.0.1 -passwordless yes'
    Write-Host '    installSdeEnv.ps1 -serverIp 172.18.0.1 -user root -passwordless yes -skipAnsibleRoles yes -mountSdeFolder yes'
    Write-Host '    installSdeEnv.ps1 -serverIp 172.18.0.1 -user root -baseDrive C: -skipAnsible yes -skipAnsibleFiles yes'
    Write-Host '    installSdeEnv.ps1 -serverIp 172.18.0.1 -user root -baseDrive C: -basePath /sde -passwordless yes'
    Write-Host '    installSdeEnv.ps1 -serverIp 172.18.0.1 -user root -baseDrive C: -basePath /sde -options "-inv=sde-support.inv -playbook=sdeEnv/main.yml -extra=targetServers=all:ansiblePath=/sde/cloud/ansible"'
    Write-Host ''
}

Function Show-Config() {
    Write-Host -ForegroundColor Yellow "SDE install script configuration"
    Write-Host -ForegroundColor Yellow "======================================================================="
    Write-Host -ForegroundColor Yellow "Operation User                        : ${user}"
    Write-Host -ForegroundColor Yellow "Ansible Server Ip                     : ${serverIp}"
    Write-Host -ForegroundColor Yellow "-----------------------------------------------------------------------"
    Write-Host -ForegroundColor Yellow "Local Base Drive                      : ${baseDrive}"
    Write-Host -ForegroundColor Yellow "Local Base Path                       : ${basePath}"
    Write-Host -ForegroundColor Yellow "Local Hyper-V PowerShell Script Path  : ${hypervPowerShellPath}"
    Write-Host -ForegroundColor Yellow "Local Shell Path                      : ${localShellPath}"
    Write-Host -ForegroundColor Yellow "-----------------------------------------------------------------------"
    Write-Host -ForegroundColor Yellow "Remote Ansible Folder                 : ${ansiblePath}"
    Write-Host -ForegroundColor Yellow "Remote Shell Path                     : ${shellPath}"
    Write-Host -ForegroundColor Yellow "-----------------------------------------------------------------------"
    Write-Host -ForegroundColor Yellow "Ansible Extra Options                 : ${options}"
    Write-Host -ForegroundColor Yellow "Ansible Verbise Options               : ${verbose}"
    Write-Host ''
}

Function Write-Message($message) {
    Write-Host -ForegroundColor Yellow "****************************************************************************************************************************************"
    Write-Host -ForegroundColor Yellow "${message}"
    Write-Host -ForegroundColor Yellow "****************************************************************************************************************************************"
    Write-Host ''
}

Function Copy-SshKey($user, $serverIp) {
    Write-Host -ForegroundColor Green "Remove host key from ~/.ssh/known_hosts"
    $knownHostsFile = '~/.ssh/known_hosts'

    If (-NOT(Test-Path -Path $knownHostsFile -PathType Leaf)) {
         Try {
             $null = New-Item -ItemType File -Path $knownHostsFile -Force -ErrorAction Stop
             Write-Host "The file [$knownHostsFile] has been created."
         } Catch {
             Throw $_.Exception.Message
         }
     } Else {
         Write-Host "Cannot create [$knownHostsFile] because a file with that name already exists."
     }

    Get-Content -Path ~/.ssh/known_hosts | Where-Object {$_ -NOTMATCH "${serverIp}"} | Set-Content -Path ~/.ssh/known_hosts_new
    cp ~/.ssh/known_hosts_new ~/.ssh/known_hosts
    rm ~/.ssh/known_hosts_new

    Write-Host -ForegroundColor Green "ssh -o StrictHostKeyChecking=no ${user}@${serverIp} 'mkdir -p ~/.ssh'"
    Write-Host -ForegroundColor Green "Type ${user}'s password for mkdir 'mkdir -p ~/.ssh'"
    ssh -o StrictHostKeyChecking=no ${user}@${serverIp} 'mkdir -p ~/.ssh'

    Write-Host -ForegroundColor Green "ssh -o StrictHostKeyChecking=no  ${user}@${serverIp} 'ls -l ~/.ssh/authorized_keys'"
    Write-Host -ForegroundColor Green "Type ${user}'s password for make '~/.ssh/authorized_keys'"
    type "~/.ssh/id_rsa.pub" | ssh ${user}@${serverIp} 'cat > ~/.ssh/authorized_keys'
    ssh -o StrictHostKeyChecking=no ${user}@${serverIp} "ls -l ~/.ssh/authorized_keys"
}

Function Copy-AnsibleAndShellFiles() {
    $targetPathList = "/etc/ansible", "${ansiblePath}/config", "${ansiblePath}/hosts", "${ansiblePath}/playbook/sdeEnv", "${ansiblePath}/roles"

    Write-Host ""
    Write-Host -ForegroundColor Green "Make SDE Env folder for Ansible Server(${serverIp})"
    Write-Host -ForegroundColor Green "==================================================================================="

    For ($i = 1; $i -LE $targetPathList.count; $i++) {
        $path = ${targetPathList}[$i - 1]

        Write-Host -ForegroundColor Green "ssh -o StrictHostKeyChecking=no ${user}@${serverIp} mkdir -p ${path}"
        ssh -o StrictHostKeyChecking=no ${user}@${serverIp} "mkdir -p ${path}"
    }

    Write-Host -ForegroundColor Green "-----------------------------------------------------------------------------------"
    Write-Host -ForegroundColor Green ""
    Write-Host -ForegroundColor Green "Copy SDE Env files for Ansible Server(${serverIp})"
    Write-Host -ForegroundColor Green "==================================================================================="

    $targetFileList = "\config\ansible.cfg", "\config\dockpack.base_utils-main.yml", "\hosts\sde-support.inv"

    For ($i = 1; $i -LE $targetFileList.count; $i++) {
        $shellPathAndFile = ${baseDrive} + ${ansiblePath} + ${targetFileList}[$i - 1]

        $shellFile = (Get-Item $shellPathAndFile).Basename
        $extension = (Get-Item $shellPathAndFile).Extension

        $folder = (Get-Item $shellPathAndFile).DirectoryName
        $localFolder = $folder.Replace(${baseDrive}, "")
        $remoteFolder = $folder.Replace(${baseDrive}, "")

        $localFolder = $localFolder.Replace("/", "\")
        $remoteFolder = $remoteFolder.Replace("\", "/")

        Write-Host -ForegroundColor Green "scp -o StrictHostKeyChecking=no ${baseDrive}/${localFolder}/${shellFile}${extension} ${user}@${serverIp}:${remoteFolder}/${shellFile}${extension}"
        scp -o StrictHostKeyChecking=no ${baseDrive}${localFolder}/${shellFile}${extension} ${user}@${serverIp}:${remoteFolder}/${shellFile}${extension}
    }

    Write-Host -ForegroundColor Green "-----------------------------------------------------------------------------------"
    Write-Host -ForegroundColor Green ""
    Write-Host -ForegroundColor Green "Copy SDE folders for Ansible Server(${serverIp})"
    Write-Host -ForegroundColor Green "==================================================================================="

    $sourceFolderList = @("${ansiblePath}/config", "${ansiblePath}/playbook/sdeEnv")
    $targetFolderList = @("${ansiblePath}/config", "${ansiblePath}/playbook/sdeEnv")

    For ($i = 1; $i -LE $targetFolderList.count; $i++) {
        $localFolder = ${sourceFolderList}[$i - 1]
        $localFolder = $localFolder.Replace("/", "\")
        $remoteFolder = ${targetFolderList}[$i - 1]

        Write-Host -ForegroundColor Green "scp -r -o StrictHostKeyChecking=no ${baseDrive}${localFolder}\* ${user}@${serverIp}:${remoteFolder}/"
        scp -r -o StrictHostKeyChecking=no ${baseDrive}${localFolder}\* ${user}@${serverIp}:${remoteFolder}/
    }

    Write-Host -ForegroundColor Green '-----------------------------------------------------------------------------------'
    Write-Host ''
}

If (($serverIp -EQ $Null -AND -$Args.Count -EQ 0) -OR ($Args[0] -MATCH "-h" -OR $Args[0] -MATCH "-help")) {
    Show-Help
    Exit
}

If ($options -EQ "") {
    $options = "--inventory=sde-support.inv,--playbook=sdeEnv/main.yml,--options=targetServers=all:ansiblePath=/sde/cloud/ansible"
}

If ($nfsServerInfo -EQ "") {
    $nfsServerInfo = "172.17.0.2:/cloud"
}

If ($serverIp -EQ $Null) {
    $serverIp = Read-HostDefault "Please enter a Server Ip" ""
}

Show-Config

If ($passwordless.toLower() -EQ "yes") {
    Copy-SshKey $user $serverIp
} Else {
    $isProceed = Read-HostDefault "Would you like to configure ssh processing without a password?" "No"

    If (($isProceed.ToLower() -EQ "yes") -OR ($isProceed.ToLower() -EQ "y")) {
        Copy-SshKey $user $serverIp
    }
}

If ($skipAll.toLOwer() -EQ "yes") {
    $skipAnsible = "yes"
    $skipAnsibleFiles = "yes"
    $skipAnsibleRoles = "yes"
}

$StartTime = $(get-date)

If ($skipAnsibleFiles.toLOwer() -EQ "no") {
    Copy-AnsibleAndShellFiles
}

$baseCommand="${hypervPowerShellPath}\sshShell.ps1 -user ${user} -serverIp ${serverIp} -shellPath ${shellPath} "

If ($skipAnsibleFiles.toLOwer() -EQ "yes") {
    $baseCommand = $baseCommand + "-copyShell no"
}

If ($skipAnsible.toLOwer() -EQ "no") {
    $sshShellCommand = $baseCommand + "-shell ${shellPath}/installAnsible.sh -options --by-pip"
    Write-Message "Depending on your internet connection, it may take 3 ~ 5 minutes to install the Ansible Server.`nExecute Cmd`n   ${sshShellCommand}"
    Invoke-Expression "${sshShellCommand}"
}

If ($mountSdeFolder.toLOwer() -EQ "yes") {
    $sshShellCommand = $baseCommand + "-shell ${shellPath}/mountFolder.sh -options $nfsServerInfo,$cloudPath"
    Write-Message "Mount SDE Folder from NFS Share folder.`nExecute Cmd`n   ${sshShellCommand}"
    Invoke-Expression "${sshShellCommand}"
}

If ($skipAnsibleRoles.toLOwer() -EQ "no") {
    $sshShellCommand = $baseCommand + "-shell ${shellPath}/installUsefulAnsibleRoles.sh"
    Write-Message "Depending on your internet connection, it may take 5 ~ 10 minutes to download Ansible Roles from Ansible Galaxy.`nExecute Cmd`n   ${sshShellCommand}"
    Invoke-Expression "${sshShellCommand}"
}

$sshShellCommand = $baseCommand + "-shell ${shellPath}/runAnsiblePlaybook.sh -options $options"

If ($verbose -NE "") {
    $sshShellCommand = $sshShellCommand + " -verbose ${verbose}"
}

Write-Message "It may take 5 ~ 20 minutes to install SDE Servers using sdeEnv/main.yml ansible playbook file.`nExecute Cmd`n   ${sshShellCommand}"
Invoke-Expression "${sshShellCommand}"

$elapsedTime = $(get-date) - $StartTime
Write-Host ''
Write-Host -ForegroundColor Green '-----------------------------------------------------------------------------------'
Write-Host -ForegroundColor Green "${hypervPowerShellPath}\InstallSdeEnv.ps1 ElapsedTime : ${elapsedTime}"
Write-Host -ForegroundColor Green '-----------------------------------------------------------------------------------'
