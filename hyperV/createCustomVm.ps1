<#
Ip Range Definition
========================================================================================
Router Ip             10.0.0.1
Private Ip Range      10.0.0.0    ~ 10.255.255.255
Linux Release         Base VM Ip    Kubenetes Work Node Ip Range
  CentOS 7.4          10.1.7.4      10.11.74.1~255
  CentOS 7.9          10.1.7.9      10.11.79.1~255
  ...                 ...
  CentOS 8.2          10.1.8.2      10.11.82.1~255
  CentOS 8.3          10.1.8.3      10.11.83.1~255

  Ubuntu 18.4         10.2.18.4     10.12.18.1~255
  Ubuntu 20.4         10.2.20.4     10.12.20.1~255

  OracleLinux 7.9     10.3.7.9      10.13.79.1~255
  ...                 ...
  OracleLinux 8.3     10.3.8.3      10.13.83.1~255

  Redhat 7.9          10.4.7.9      10.14.79.1~255
  ...                 ...
  Redhat 8.3          10.4.8.3      10.14.83.1~255

Router Ip             172.16.0.1
Private Ip Range      172.16.0.0  ~ 172.31.255.255
Linux Release         Base VM Ip    Kubenetes Work Node Ip Range
  CentOS 7.4          172.16.7.4    172.21.74.1~255
  CentOS 7.9          172.16.7.9    172.21.79.1~255
  ...                 ...
  CentOS 8.2          172.16.8.2    172.21.82.1~255
  CentOS 8.3          172.16.8.3    172.21.83.1~255

  Ubuntu 18.4         172.17.18.4   172.22.18.1~255
  Ubuntu 20.4         172.17.20.4   172.22.20.1~255

  OracleLinux 7.9     172.18.7.9    172.23.79.1~255
  ...                 ...
  OracleLinux 8.3     172.18.8.3    172.23.83.1~255

  Redhat 7.9          172.19.7.9    172.24.79.1~255
  ...                 ...
  Redhat 8.3          172.19.8.3    172.24.83.1~255

Router Ip             192.168.0.1
Private Ip Range      192.168.0.0 ~ 192.168.255.255
Linux Release         Base VM Ip    Kubenetes Work Node Ip Range
  CentOS 7.4          192.168.1.74  192.168.74.1~255
  CentOS 7.9          192.168.1.79  192.168.79.1~255
  ...                 ...
  CentOS 8.2          192.168.1.82  192.168.82.1~255
  CentOS 8.3          192.168.1.83  192.168.83.1~255

  Ubuntu 18.4         192.168.2.84  192.168.18.1~255
  Ubuntu 20.4         192.168.2.204 192.168.20.1~255

  OracleLinux 7.9     192.168.3.79  192.168.129.1~255    + 50
  ...                 ...
  OracleLinux 8.3     192.168.3.83  192.168.133.1~255

  Redhat 7.9          192.168.4.79  192.168.179.1~255    + 100
  ...                 ...
  Redhat 8.3          192.168.4.83  192.168.183.1~255
#>

Function Read-HostDefault($prompt, $default) {
    $prompt = "$prompt [$default]"
    $val = Read-Host $prompt
    ($default,$val)[[bool]$val]
}

Function Select-ReadDefault($selectList, $prompt, $default) {
    Foreach ($item in $selectList) {
        Write-Host -ForegroundColor Yellow $selectList.indexOf($item) " - ${item}"
    }

    Read-HostDefault $prompt $default
}

Function Select-VmOs() {
    $vmIndex = 0
    $vmList = Get-VM -Name BaseVm* | Select -Expand Name

    Foreach ($vm in $vmList) {
        Write-Host "${vmIndex} -" ${vm}
        $vmIndex += 1
    }

    $baseOsNo = Read-HostDefault "Please enter a Base Os/Version Name" 0
    Return $vmList[${baseOsNo}]
}

Function CheckAndMakeSshKey() {
    $keyList = Get-ChildItem -Path $HOME\.ssh id_rsa.pub | Select -Expand Name

    If ($keyList.Length -eq 0) {
        ssh-keygen
    }
}

Function ExecuteSshShell($user, $baseVmIp, $password, $awaitCommand) {
    Write-Host -ForegroundColor Yellow "Execute Shell Command => $awaitCommand"
    Write-Host -ForegroundColor Yellow "Send awaitCommand to ${baseVmIp} Remote Server."

    Start-AwaitSession
    Send-AwaitCommand $awaitCommand

    Write-Host -ForegroundColor Yellow "Waiting for password input $baseVmIp Remote Server."
    $output = Wait-AwaitResponse "password:" -All

    Write-Host -ForegroundColor Yellow "Send a password to $baseVmIp Remote Server."
    Send-AwaitCommand $password
    Stop-AwaitSession
}

Function SshCopyId($user, $baseVmIp, $password) {
    $awaitCommand = "scp -o StrictHostKeyChecking=no ${HOME}/.ssh/id_rsa.pub ${user}@${baseVmIp}:~/.ssh/authorized_keys"

    ExecuteSshShell $user $baseVmIp $password $awaitCommand
}

Function GetOsInfo($baseOsName, $baseVmIpNo) {
    $osNameInfo = $baseOsName.Split("-")[1]
    $osName = $osNameInfo -REPLACE '[0-9.]'
    $osVersion = $osNameInfo -REPLACE '[a-zA-Z]'
    $octetIp = ""
    $startIp = ""
    $gatewayIp = ""
    $netmask = ""

    Switch  ($baseVmIpNo) {
        0 { $octetIp = "" }
        1 {
            $netmask = "255.0.0.0"
            $gatewayIp = "10.0.0.1"
            $octetIp = "10." + $baseVmIpNo + "." + $osVersion
            $cOctetIp = $osVersion -REPLACE '[.]'

            Switch  ($osName) {
                CentOS { $startIp = "10.11." + $cOctetIp + ".1" }
                Ubuntu { $startIp = "10.12." + $cOctetIp + ".1" }
                OracleLinux { $startIp = "10.13." + $cOctetIp + ".1" }
                Redhat { $startIp = "10.13." + $cOctetIp + ".1" }
            }
        }
        2 {
            $netmask = "255.240.0.0"
            $gatewayIp = "172.16.0.1"
            $cOctetIp = $osVersion -REPLACE '[.]'

            Switch  ($osName) {
                CentOS { $octetIp = "172.16." + $osVersion; $startIp = "172.21." + $cOctetIp + ".1" }
                Ubuntu { $octetIp = "172.17." + $osVersion; $startIp = "172.22." + $cOctetIp + ".1" }
                OracleLinux { $octetIp = "172.18." + $osVersion; $startIp = "172.23." + $cOctetIp + ".1" }
                Redhat { $octetIp = "172.19." + $osVersion; $startIp = "172.24." + $cOctetIp + ".1" }
            }
        }
        3 {
            $netmask = "255.255.0.0"
            $gatewayIp = "192.168.0.1"
            $cOctetIp = $osVersion -REPLACE '[.]'

            Switch  ($osName) {
                CentOS { $octetIp = "192.168.1." + $cOctetIp; $startIp = "192.168." + $cOctetIp + ".1" }
                Ubuntu { $octetIp = "192.168.2." + $cOctetIp; $startIp = "10.168." + $cOctetIp + ".1" }
                OracleLinux { $octetIp = "192.168.3." + $cOctetIp; $startIp = "192.168." + ([int]$cOctetIp + 50)+ ".1" }
                Redhat { $octetIp = "192.168.4." + $cOctetIp; $startIp = "192.168.1" + $cOctetIp + ".1" }
            }
        }
    }

    Return $osName, $osVersion, $octetIp, $startIp, $gatewayIp, $netmask
}

Function GetIpList($totalVm, $ipOctetA, $ipOctetB, $ipOctetC, $ipOctetD) {
    $ipList = ""

    For ($i = 1; $i -le $totalVm; $i++) {
        If ($i -EQ 1) {
            $ipList += "${ipOctetA}.${ipOctetB}.${ipOctetC}.${ipOctetD}"
        } Else {
            $ipList += ",${ipOctetA}.${ipOctetB}.${ipOctetC}.${ipOctetD}"
        }

        If ($ipOctetD -eq 255) {
            $ipOctetD = 1
            $ipOctetC += 1

            If ($ipOctetC -eq 255) {
                $ipOctetC = 0
                $ipOctetB += 1
            }
        }

        $ipOctetD += 1
    }

    Return $ipList
}

Function GetTemplateNamePatterns($totalVm, $namePattern) {
    $completeNames = ""

    For ($i = 1; $i -le $totalVm; $i++) {
        If ($i -EQ 1) {
            $completeNames += $namePattern.Replace("%{seq}", "$i")
        } Else {
            $completeNames += "," + $namePattern.Replace("%{seq}", "$i")
        }
    }

    Return $completeNames
}

If (Test-Path "~/.ssh/id_rsa") {
    Write-Host -ForegroundColor Yellow "The Ssh key is exist..... SKIP"
} Else {
    Write-Host -ForegroundColor Yellow "There is no Ssh Key to be connect to the created VM."
    ssh-keygen -t rsa
    Write-Host " "
}

$isInstalled = Get-package | Where-Object {$_.Name -match 'Await' } | Select -Expand Name

If ($isInstalled -EQ "Await") {
    Write-Host -ForegroundColor Yellow "The Await package is installed..... SKIP"
} Else {
    Write-Host -ForegroundColor Yellow "The Await package is not installed."
    Write-Host -ForegroundColor Yellow "Install Await package"
    Install-Module -Name Await
    Write-Host " "
}

$linuxDist = ""
$configFile = $args[0]
$fromConfigFile = "NO"
$adapterName = "Network Adapter"

If ($configFile -NE $Null) {
    Get-Content $configFile | Foreach-Object -begin { $configMap = @{} } -process {
        $k = [regex]::split($_,'=');
        If (($k[0].Trim().CompareTo("") -Ne 0) -And ($k[0].StartsWith("[") -NE $True)) {
            $configMap.Add($k[0], $k[1])
        }
    }

    $fromConfigFile = "YES"
    $howToCreateVm = $configMap["howToCreateVm"]
    [int]$totalVm = $configMap["totalVm"]
    $baseOsName = $configMap["baseOsName"]
    $vmMemorySize = $configMap["vmMemorySize"]

    $dynamicMemoryEnabled = $configMap["dynamicMemoryEnabled"]
    $dynamicStartupBytes = $configMap["dynamicStartupBytes"]
    $dynamicMinimumBytes = $configMap["dynamicMinimumBytes"]
    $dynamicMaximumBytes = $configMap["dynamicMaximumBytes"]

    [int]$processorCount = $configMap["processorCount"]
    [int]$vmGeneration = $configMap["vmGeneration"]
    $vmBasePath = $configMap["vmBasePath"]
    $targetVmPath = $configMap["targetVmPath"]
    $resetShellFile = $configMap["resetShellFile"]
    $resetShellFilePath = $configMap["resetShellFilePath"]

    $presetByBaseVmAndOsName = $configMap["preset"]
    [int]$ipRange = $configMap["ipRange"]
    $switchName = $configMap["switchName"]
    $baseVmIp = $configMap["baseVmIp"]
    $targetIp = $configMap["targetIp"]
    $startIp = $configMap["startIp"]

    If ($baseOsName -match "Ubuntu") {
        $prefix = $configMap["prefix"]
        $dns = $configMap["dns"]
    } Else {
        $netmask = $configMap["netmask"]
        $dns1 = $configMap["dns1"]
        $dns2 = $configMap["dns2"]
    }

    $mtu = $configMap["mtu"]
    $gatewayIp = $configMap["gatewayIp"]
    $search = $configMap["search"]
    $vmNameTemplate = $configMap["vmNameTemplate"]
    $hostNamePrefix = $configMap["hostNamePrefix"]
    $hostNameTemplate = $configMap["hostNameTemplate"]
    $hostTypeTemplate = $configMap["hostTypeTemplate"]
    $user = $configMap["user"]
    $password = $configMap["password"]

    $targetDiskSize = [int]$configMap["targetDiskSize"]
    $targetDiskPath = $configMap["targetDiskPath"]
    $startUp = $configMap["startUp"]
    $pingTest = $configMap["pingTest"]

    $addAnsibleHost = $configMap["addAnsibleHost"]
    $addAnsibleHostFile = $configMap["addAnsibleHostFile"]
    $addAnsibleHostPath = $configMap["addAnsibleHostPath"]
    $addAnsibleHostGroup = $configMap["addAnsibleHostGroup"]
    $addAnsibleHostOptions = $configMap["addAnsibleHostOptions"]

    if ($presetByBaseVmAndOsName -EQ "yes") {
        $osName, $osVersion, $baseVmIp, $presetStartIp, $gatewayIp, $netmask = GetOsInfo $baseOsName $ipRange
        [int]$ipOctetA, [int]$ipOctetB, [int]$ipOctetC, [int]$ipOctetD = $presetStartIp.split(".")
        $targetIp = GetIpList $totalVm $ipOctetA $ipOctetB $ipOctetC $ipOctetD
    }

    If ($startIp -NE $Null) {
        [int]$ipOctetA, [int]$ipOctetB, [int]$ipOctetC, [int]$ipOctetD = $startIp.split(".")
        $targetIp = GetIpList $totalVm $ipOctetA $ipOctetB $ipOctetC $ipOctetD
    }
}

If ($fromConfigFile -EQ "NO") {
    $resetShellFile = "resetHost.sh"

    Write-Host -ForegroundColor Yellow "Please enter the information for creating the VM."
    Write-Host -ForegroundColor Yellow "Collecting switch information and drive information...`n"

    $switchList = Get-VMSwitch  * | Select -Expand Name
    $driveInfoList = Get-Volume | Where-Object {$_.DriveLetter -match '^[A-Z]' } | Select DriveLetter,FileSystemLabel | Sort-Object -Property DriveLetter
    $baseVmPathList = New-Object System.Collections.ArrayList
    $targetVmPathList = New-Object System.Collections.ArrayList

    ForEach ($driveInfo in $driveInfoList) {
        $drive = $driveInfo.driveLetter + ":"
        $folderList = Get-ChildItem -Directory -Path $drive Hyper-V* | Select -Expand Name

        ForEach ($folder in $folderList) {
            If ($folder -MATCH "BaseVm") {
                $baseVmPathList.Add($drive + $folder + " => " + $driveInfo.fileSystemLabel + " Volume") | Out-Null
            }

            If ($folder -NOTMATCH "BaseVm") {
                $targetVmPathList.Add($drive + $folder + " => " + $driveInfo.fileSystemLabel + " Volume") | Out-Null
            }
        }
    }

    $howToCreateVmList = "Same Type   => Enter the Start IP and hostname pattern.", "Custom Type => Enter the IP and hostname list directly."
    $howToCreateVm = Select-ReadDefault $howToCreateVmList "Please enter Vm creation method " 0

    $totalVm = Read-HostDefault "Please enter the number of Vm to be created" 4
    $baseOsName = Select-VmOs
    $vmMemorySize = Read-HostDefault "Please enter a Vm Memory Size(BaseUnit GB)" 2
    $processorCount = Read-HostDefault "Please enter a Process Count" 4
    $vmGeneration = Read-HostDefault "Please enter Vm generation " 2

    $defaultVmPathNo = $baseVmPathList.Count - 1
    $vmPathNo = Select-ReadDefault $baseVmPathList "Please enter the installed Base OS image folder." $defaultVmPathNo
    $vmBasePath = $baseVmPathList[$vmPathNo].split("=>")[0].Trim()

    $vmPathNo = Select-ReadDefault $targetVmPathList "Please enter the name of the new Hyper-V folder to be created." $defaultVmPathNo
    $targetVmPath = $targetVmPathList[$vmPathNo].split("=>")[0].Trim()

    $defaultSwitchNo = $switchList.Length - 1
    $switchNo = Select-ReadDefault $switchList "Please enter a Switch Name" $defaultSwitchNo
    $switchName = $switchList[$switchNo]

    $baseVmIpList = "public ips", "10.0.0.0 ~ 10.255.255.255", "172.16.0.0 ~ 172.31.255.255", "192.168.0.0 ~ 192.168.255.255"
    $ipRange = Select-ReadDefault $baseVmIpList "Please enter a Target Ip Area" 2

    $osName, $osVersion, $baseVmIp, $startIp, $gatewayIp, $netmask = GetOsInfo $baseOsName $ipRange
    $baseVmIp = Read-HostDefault "Please enter a preset IP address of installed ${baseOsName}" $baseVmIp

    If ($howToCreateVm -EQ "0") {
        [int]$ipOctetA, [int]$ipOctetB, [int]$ipOctetC, [int]$ipOctetD = $startIp.split(".")
        $targetIp = GetIpList $totalVm $ipOctetA $ipOctetB $ipOctetC $ipOctetD
        $targetIp = Read-HostDefault "Please enter a Ip addresses" $targetIp
    } Else {
        Write-Host "Enter the IP addresses"
        Write-Host "Ex) 172.21.79.1,172.21.79.2,172.21.79.3,...1"

        $targetIp = Read-HostDefault "Please enter a Ip addresses"
    }

    If ($baseOsName -MATCH "Ubuntu") {
        $prefix = Read-HostDefault "Please enter a prefix" "24"

        $dns = Read-HostDefault "Please enter a DNS IP Address" "8.8.8.8"
    } Else {
        $netmask = Read-HostDefault "Please enter a netmask" $netmask

        $dns1 = Read-HostDefault "Please enter a DNS1 IP Address" "8.8.8.8"
        $dns2 = Read-HostDefault "Please enter a DNS2 IP Address" ${dns2}
    }

    $gatewayIp = Read-HostDefault "Please enter a Gateway IP Address" ${gatewayIp}
    $mtu = Read-HostDefault "Please enter a mtu" "9000"
    $search = Read-HostDefault "Please enter a Search Domain" "online9.com"

    Write-Host -ForegroundColor Yellow "Enter the Vm and Host Name Patterns"
    Write-Host -ForegroundColor Yellow "Ex) Vm Create Count : 3, BaseVm Name : BaseVm-CentOS7.9"
    Write-Host -ForegroundColor Yellow "  VmName Pattern        : KubeAwx,KubeScm,KubeCi => KubeAwx-CentOS7.9,KubeScm-CentOS7.9,KubeCi-CentOS7.9"
    Write-Host -ForegroundColor Yellow "  Seq VmName Pattern    : KubeNode%{seq} => KubeNode1-CentOS7.9,KubeNode2-CentOS7.9,KubeNode3-CentOS7.9"
    Write-Host -ForegroundColor Yellow "  Hostname Pattern      : kube-awx,kube-scm,kube-ci"
    Write-Host -ForegroundColor Yellow "  Seq Hostname Pattern  : kube-node-%{seq} => kube-node-1,kube-node-2,kube-node-3"

    $vmNameTemplate = Read-HostDefault "Please enter a Hyper-V Vm Name Patterns"
    $hostNameTemplate = Read-HostDefault "Please enter a OS(Linux/Ubuntu) Hostname Patterns"
    $user = Read-HostDefault "Please enter a user" "root"

    Do {
        $pw1 = Read-Host "`nPlease enter a password for Ssh operation" -AsSecureString
        $pw2 = Read-Host "Please re-enter a password for Ssh operation" -AsSecureString

        $password = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw1))
        $confirmPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($pw2))

        If ($password -eq "") {
            Write-Host -ForegroundColor Red "Password is required... Re-Enter a password"
            Continue
        }

        If ($password -ne $confirmPassword) {
            Write-Host -ForegroundColor Red "Passwords do not match... Re-Enter a password"
        } Else {
            Break
        }
    } While ($password -ne $confirmPassword)

    $startUp = Read-HostDefault "Would you like to reboot Vms completing all settings?" "yes"
    $pingTest = Read-HostDefault "Would you like to ping test?" "yes"

    $addAnsibleHost = Read-HostDefault "Would you like to add Ansible hosts?" "yes"

    If ($addAnsibleHost -EQ "yes") {
        $addAnsibleHostPath = Read-HostDefault "Please enter a ansible host file path" "ansible/hosts"
        $addAnsibleHostFile = Read-HostDefault "Please enter a ansible host file name" "hosts.ini"
        $addAnsibleHostGroup = Read-HostDefault "Please enter a ansible host group name" "group"
        $addAnsibleHostOptions = Read-HostDefault "Please enter a ansible host options" "ssh_user=online9"
    }
}

If ($resetShellFilePath -EQ $Null) {
    $resetShellFilePath = "../shell/"
}

$addAnsibleHostOptions = ${addAnsibleHostOptions} -creplace ":", "="

Write-Host " "
Write-Host -ForegroundColor Yellow "New VMs are created by copying the selected template VM."
Write-Host -ForegroundColor Yellow "======================================================================="
Write-Host -ForegroundColor Yellow "Process              : ${processorCount}"
Write-Host -ForegroundColor Yellow "Memory               : ${vmMemorySize}GB"
Write-Host -ForegroundColor Yellow "Vm Generation        : ${vmGeneration}"
Write-Host -ForegroundColor Yellow "Switch               : ${switchName}"
Write-Host -ForegroundColor Yellow "BaseVm Ip            : ${baseVmIp}"
Write-Host -ForegroundColor Yellow "Gateway Ip           : ${gatewayIp}"

If ($baseOsName -match "Ubuntu") {
    Write-Host -ForegroundColor Yellow "PREFIX               : ${prefix}"
    Write-Host -ForegroundColor Yellow "DNS                  : ${dns}"
} Else {
    Write-Host -ForegroundColor Yellow "NETMASK              : ${netmask}"
    Write-Host -ForegroundColor Yellow "DNS1                 : ${dns1}"
    Write-Host -ForegroundColor Yellow "DNS2                 : ${dns2}"
}

Write-Host -ForegroundColor Yellow "MTU                  : ${mtu}"
Write-Host -ForegroundColor Yellow "Search Domain        : ${search}"
Write-Host -ForegroundColor Yellow "Vm Folder            : ${targetVmPath}"

If ($targetDiskPath -NE "NONE") {
  Write-Host -ForegroundColor Yellow "Etc Hdd Size         : ${targetDiskSize}GB"
}

Write-Host -ForegroundColor Yellow "User                 : ${user}"
Write-Host -ForegroundColor Yellow "-----------------------------------------------------------------------"
Write-Host -ForegroundColor Yellow "Host Reset Shell     : ${resetShellFilePath}${resetShellFile}"

If ($addAnsibleHost -EQ "yes") {
    Write-Host -ForegroundColor Yellow "Ansible Host file    : ${addAnsibleHostPath}/${addAnsibleHostFile}"
    Write-Host -ForegroundColor Yellow "Ansible Host Group   : ${addAnsibleHostGroup}"
    Write-Host -ForegroundColor Yellow "Ansible Host Options : ${addAnsibleHostOptions}"
}

Write-Host -ForegroundColor Yellow "-----------------------------------------------------------------------"

$targetOsVersion = ${baseOsName}.split("-")[1]
$baseVhdxName = "${vmBasePath}\${baseOsName}\Virtual Hard Disks\${baseOsName}.vhdx"

If ($vmNameTemplate -MATCH "%{seq}") {
    $vmNameTemplate = GetTemplateNamePatterns $totalVm $vmNameTemplate
}

If ($hostNameTemplate -MATCH "%{seq}") {
    $hostNameTemplate = GetTemplateNamePatterns $totalVm $hostNameTemplate
}

$targetIp = ${targetIp}.split(",")
$vmNameTemplate = ${vmNameTemplate}.split(",")
$hostNameTemplate = ${hostNameTemplate}.split(",")

For ($i = 1; $i -le $targetIp.count; $i++) {
    $vmName = ${vmNameTemplate}[$i - 1]
    $vmName = "${vmName}-${targetOsVersion}"
    $vmIp = ${targetIp}[$i - 1]

    Write-Host -ForegroundColor Yellow "${targetVmPath}\${vmName}, Ip Address : ${vmIp}"
}

Write-Host -ForegroundColor Yellow "-----------------------------------------------------------------------"

$isProceed = Read-HostDefault "Do you want to create new Vms" "Yes"

If ($isProceed -ne "Yes") {
    Exit
}

$StartTime = $(get-date)

If (!(Test-Path ${baseVhdxName})) {
    Write-Host -ForegroundColor Red "${baseVhdxName} file not found..... "
    Exit
}

$isProceed = Read-HostDefault "Would you like to configure ssh processing without a password?" "No"

If ($isProceed.ToLower() -eq "yes") {
    Write-Host -ForegroundColor Green "Start ${baseOsName} Vm for processing without a password and Wait 10 seconds"
    Start-VM -Name ${baseOsName}
    Start-Sleep -s 10
    ping ${baseVmIp}

    Write-Host -ForegroundColor Green "Remove host key from ~/.ssh/known_hosts"
    Get-Content -Path ~/.ssh/known_hosts | Where-Object {$_ -notmatch "${baseVmIp}"} | Set-Content -Path ~/.ssh/known_hosts_new
    cp ~/.ssh/known_hosts_new ~/.ssh/known_hosts
    rm ~/.ssh/known_hosts_new

    Write-Host -ForegroundColor Green "Type ${user}'s password for mkdir 'mkdir -p ~/.ssh'"
    ssh -o StrictHostKeyChecking=no ${user}@${baseVmIp} 'mkdir -p ~/.ssh'

    Write-Host -ForegroundColor Green "Type ${user}'s password for make '~/.ssh/authorized_keys'"
    type "~/.ssh/id_rsa.pub" | ssh ${user}@${baseVmIp} 'cat > ~/.ssh/authorized_keys'
    ssh ${user}@${baseVmIp} "ls -l ~/.ssh/authorized_keys"

    Stop-VM -Name ${baseOsName}
    Write-Host -ForegroundColor Green "Stop ${baseOsName} Vm for processing without a password and Wait 20 seconds"
    Start-Sleep -s 20
}

For ($i = 1; $i -le $targetIp.count; $i++) {
    $vmName = ${vmNameTemplate}[$i - 1]
    $vmName = "${vmName}-${targetOsVersion}"
    $vmDiskName = "${targetVmPath}\${vmName}\Virtual Hard Disks\${vmName}.vhdx"
    $Exists = Get-Vm -name ${vmName} -ErrorAction SilentlyContinue

    If ($Exists) {
        Write-Host -ForegroundColor Red "VM ${vmName} is exists"
        Stop-VM -Name ${vmName} -Force
        Remove-VM -Name ${vmName} -Force
        Remove-Item -Force -Recurse -Path "${targetVmPath}\${vmName}"
        Write-Host -ForegroundColor Red "${targetVmPath}\${vmName} folders are removed....."
    }

    Write-Host -ForegroundColor Green "Start ${vmName} Vm creation."
    [long]$memorySize = [int]${vmMemorySize} * 1024 * 1024

    Try {
        Write-Host -ForegroundColor Green "${vmName} Vm creation Option."
        Write-Host -ForegroundColor Green "  =>  memorySize : ${memorySize}, Path ${targetVmPath}, NewVHDPath :${vmDiskName}"

        If ($vmGeneration -eq 2) {
            New-VM -Name ${vmName} -MemoryStartupBytes ${memorySize} -BootDevice VHD -NewVHDPath "${vmDiskName}" -Path ${targetVmPath} -NewVHDSizeBytes 8GB -Generation 2 -Switch ${switchName}
        } else {
            New-VM -Name ${vmName} -MemoryStartupBytes ${memorySize} -BootDevice VHD -NewVHDPath "${vmDiskName}" -Path ${targetVmPath} -NewVHDSizeBytes 8GB -Switch ${switchName}
        }

        If ($targetDiskPath) {
            [long]$hddSize = ${targetDiskSize} * 1024 * 1024 * 1024

            New-VHD -Path "${targetDiskPath}\${vmName}\Virtual Hard Disks\${vmName}-Etc.vhdx" -Dynamic -SizeBytes $hddSize
            Add-VMHardDiskDrive -VMName ${vmName} -Path "${targetDiskPath}\${vmName}\Virtual Hard Disks\${vmName}-Etc.vhdx"
            Write-Host -ForegroundColor Green "${targetDiskPath}\${vmName}\Virtual Hard Disks\${vmName}-Etc.vhdx Disk is created and added."
        }

        If ($dynamicMemoryEnabled -EQ "true") {
            [long]$startupBytes = [int]$dynamicStartupBytes * 1024 * 1024
            [long]$minimumBytes = [int]$dynamicMinimumBytes * 1024 * 1024
            [long]$maximumBytes = [int]$dynamicMaximumBytes * 1024 * 1024
            Set-VMMemory ${vmName} -DynamicMemoryEnabled $true -StartupBytes $startupBytes -MinimumBytes $minimumBytes -MaximumBytes $maximumBytes
            Write-Host -ForegroundColor Green "${vmName} Vm is set to use dynamic memory allocation."
            Write-Host -ForegroundColor Green "  => StartupBytes : ${dynamicStartupBytes}MB"
            Write-Host -ForegroundColor Green "  => MinimumBytes : ${dynamicMinimumBytes}MB"
            Write-Host -ForegroundColor Green "  => MaximumBytes : ${dynamicMaximumBytes}MB). "
        }

        Write-Host -ForegroundColor Green "${vmName} Vm is created."
        Write-Host -ForegroundColor Green "${vmName} Vm is Setting."
        Set-VM -Name ${vmName} -ProcessorCount ${processorCount}

        If ($VmGeneration -eq 2) {
            Set-VMFirmware ${vmName} -EnableSecureBoot Off
        }

        Copy-Item -Path ${baseVhdxName} -Destination "${vmDiskName}"
        Write-Host -ForegroundColor Green "Copy ${baseVhdxName} => ${vmDiskName}"
        Write-Host -ForegroundColor Green "${vmName} VM is created."
        Write-Host " "
    } Catch {
        Write-Host -ForegroundColor Red "An error occurred:"
        Write-Host -ForegroundColor Red $_

        Exit
    }

    Write-Host -ForegroundColor Green "Start ${vmName} Vm"
    Start-VM -Name ${vmName}
    Write-Host -ForegroundColor Green "${vmName} is started..... Wait 10 seconds for Server startup"
    Start-Sleep -s 5

    If ($pingTest -eq "yes" ) {
        Write-Host -ForegroundColor Green "Start ${vmName} : ${baseVmIp} ping test"
        ping ${baseVmIp}
    }

    $vmIp = ${targetIp}[$i - 1]
    $hostName = ${hostNameTemplate}[$i - 1]

    If ($hostNamePrefix -NE $Null) {
        $hostName = $hostNamePrefix + "-" + $hostName
    }

    Write-Host -ForegroundColor Green "scp ${resetShellFilePath}${resetShellFile} $user@${baseVmIp}:~/$resetShellFile"
    scp ${resetShellFilePath}${resetShellFile} $user@${baseVmIp}:~/$resetShellFile

    If ($baseOsName -match "Ubuntu") {
        Write-Host -ForegroundColor Green "ssh $user@${baseVmIp} sh ~/${resetShellFile} --host=${hostName} --ip=${vmIp} --gw=${gatewayIp} --prefix=${prefix} --dns=${dns} --mtu=${mtu} --search=${search}"
        ssh $user@${baseVmIp} "sh ~/${resetShellFile} --host=${hostName} --ip=${vmIp} --gw=${gatewayIp} --prefix=${prefix} --dns=${dns} --mtu=${mtu} --search=${search}"
    } Else {
        Write-Host -ForegroundColor Green "ssh $user@${baseVmIp} sh ~/${resetShellFile} --host=${hostName} --ip=${vmIp} --gw=${gatewayIp} --netmask=${netmask} --dns1=${dns1} --dns2=${dns2} --mtu=${mtu} --search=${search}"
        ssh $user@${baseVmIp} "sh ~/${resetShellFile} --host=${hostName} --ip=${vmIp} --gw=${gatewayIp} --netmask=${netmask} --dns1=${dns1} --dns2=${dns2} --mtu=${mtu} --search=${search}"
    }

    Write-Host -ForegroundColor Green "Remove rm -f ~/${resetShellFile}"
    ssh $user@${baseVmIp} "rm -f ~/${resetShellFile}"

    Write-Host -ForegroundColor Red "Stop ${vmName} Vm"
    Stop-VM -Name ${vmName}
}

If ($startUp -eq "yes") {
    For ($i = 1; $i -le $targetIp.count; $i++) {
        $vmName = ${vmNameTemplate}[$i - 1]
        $vmName = "${vmName}-${targetOsVersion}"

        Write-Host -ForegroundColor Green "Restart ${vmName}"
        Start-VM -Name ${vmName}
    }

    Write-Host -ForegroundColor Red "Wait 30 seconds for restarting All Vm"
    Start-Sleep -s 30

    For ($i = 1; $i -le $targetIp.count; $i++) {
        $vmName = ${vmNameTemplate}[$i - 1]
        $vmName = "${vmName}-${targetOsVersion}"
        $vmIp = ${targetIp}[$i - 1]

        If ($pingTest -eq "yes" ) {
            Write-Host -ForegroundColor Green "Start ${vmName} : ${vmIp} ping test"
            ping ${vmIp}
        }
    }
}

If ($addAnsibleHost -eq "yes") {
    Write-Host -ForegroundColor Green "Make Ansible Host file for ${addAnsibleHostGroup}"

    "#Ansible Host ${addAnsibleHostGroup}" | Out-File -Encoding ASCII -FilePath ${addAnsibleHostPath}/${addAnsibleHostFile}
    Add-Content -Path ${addAnsibleHostPath}/${addAnsibleHostFile} -Value " "
    Add-Content -Path ${addAnsibleHostPath}/${addAnsibleHostFile} -Value "[${addAnsibleHostGroup}]"

    For ($i = 1; $i -le $targetIp.count; $i++) {
        $vmName = ${vmNameTemplate}[$i - 1]
        $vmIp = ${targetIp}[$i - 1]
        $hostName = ${hostNameTemplate}[$i - 1]
        $hostType = ${hostTypeTemplate}[$i - 1]
        $finalAnsibleHostOptions = $addAnsibleHostOptions.Replace("%{hostNameTemplate}", ${hostName}).Replace("%{hostType}", "");
        Add-Content -Path ${addAnsibleHostPath}/${addAnsibleHostFile} -Value "${vmName} ${vmIp} ${finalAnsibleHostOptions}"
    }
}

$elapsedTime = $(get-date) - $StartTime
Write-Host -ForegroundColor Yellow "ElapsedTime : ${elapsedTime}"