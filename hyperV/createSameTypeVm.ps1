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

Function ExecuteSshShell($user, $vmBaseIp, $password, $awaitCommand) {
    Write-Host -ForegroundColor Yellow "Execute Shell Command => $awaitCommand"
    Write-Host -ForegroundColor Yellow "Send awaitCommand to ${vmBaseIp} Remote Server."

    Start-AwaitSession
    Send-AwaitCommand $awaitCommand

    Write-Host -ForegroundColor Yellow "Waiting for password input $vmBaseIp Remote Server."
    $output = Wait-AwaitResponse "password:" -All

    Write-Host -ForegroundColor Yellow "Send a password to $vmBaseIp Remote Server."
    Send-AwaitCommand $password
    Stop-AwaitSession
}

Function SshCopyId($user, $vmBaseIp, $password) {
    $awaitCommand = "scp -o StrictHostKeyChecking=no ${HOME}/.ssh/id_rsa.pub ${user}@${vmBaseIp}:~/.ssh/authorized_keys"

    ExecuteSshShell $user $vmBaseIp $password $awaitCommand
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

$configFile = $args[0]
$fromConfigFile = "NO"
$adapterName = "Network Adapter"

If ($configFile -NE $Null ) {
    Get-Content $configFile | Foreach-Object -begin { $configMap = @{} } -process {
        $k = [regex]::split($_,'=');
        If (($k[0].Trim().CompareTo("") -Ne 0) -And ($k[0].StartsWith("[") -NE $True)) {
            $configMap.Add($k[0], $k[1])
        }
    }

    $fromConfigFile = "YES"
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
    $switchName = $configMap["switchName"]
    $vmBaseIp = $configMap["vmBaseIp"]
    $ipOctetA = $configMap["ipOctetA"]
    $ipOctetB = $configMap["ipOctetB"]
    $ipOctetC = $configMap["ipOctetC"]
    $ipOctetD = $configMap["ipOctetD"]

    If ($baseOsName -match "Ubuntu") {
        $prefix = $configMap["prefix"]
        $dns = $configMap["dns"]
    } Else {
        $netmask = $configMap["netmask"]
        $dns1 = $configMap["dns1"]
        $dns2 = $configMap["dns2"]
    }

    $netmask = $configMap["netmask"]
    $dns1 = $configMap["dns1"]
    $dns2 = $configMap["dns2"]
    $gatewayIp = $configMap["gatewayIp"]
    $search = $configMap["search"]
    $vmNameTemplate = $configMap["vmNameTemplate"]
    $hostNameTemplate = $configMap["hostNameTemplate"]
    $user = $configMap["user"]
    $password = $configMap["password"]

    $targetDiskSize = [int]$configMap["targetDiskSize"]
    $targetDiskPath = $configMap["targetDiskPath"]
}

If ($fromConfigFile -EQ "NO") {
    $resetShellFile = "resetHost.sh"

    Write-Host -ForegroundColor Yellow "Please enter the information for creating the VM."
    Write-Host -ForegroundColor Yellow "Collecting switch information and drive information...`n"

    $switchList = Get-VMSwitch  * | Select -Expand Name
    $driveInfoList = Get-Volume | Where-Object {$_.DriveLetter -match '^[A-Z]' } | Select DriveLetter,FileSystemLabel | Sort-Object -Property DriveLetter
    $targetVmPathList = New-Object System.Collections.ArrayList

    ForEach ($driveInfo in $driveInfoList) {
        $drive = $driveInfo.driveLetter + ":"
        $folderList = Get-ChildItem -Directory -Path $drive Hyper-V* | Select -Expand Name

        ForEach ($folder in $folderList) {
            $targetVmPathList.Add($drive + $folder + " => " + $driveInfo.fileSystemLabel + " Volume") | Out-Null
        }
    }

    $totalVm = Read-HostDefault "Please enter the number of Vm to be created" 4
    $baseOsName = Select-VmOs
    $vmMemorySize = Read-HostDefault "Please enter a Vm Memory Size(BaseUnit GB)" 2
    $processorCount = Read-HostDefault "Please enter a Process Count" 4
    $vmGeneration = Read-HostDefault "Please enter Vm generation " 2

    $defaultVmPathNo = $targetVmPathList.Count - 1
    $vmPathNo = Select-ReadDefault $targetVmPathList "Please enter the installed Base OS image folder." $defaultVmPathNo
    $vmBasePath = $targetVmPathList[$vmPathNo].split("=>")[0].Trim()

    $vmPathNo = Select-ReadDefault $targetVmPathList "Please enter the name of the new Hyper-V folder to be created." $defaultVmPathNo
    $targetVmPath = $targetVmPathList[$vmPathNo].split("=>")[0].Trim()

    $defaultSwitchNo = $switchList.Length - 1
    $switchNo = Select-ReadDefault $switchList "Please enter a Switch Name" $defaultSwitchNo
    $switchName = $switchList[$switchNo]

    $vmBaseIpList = "192.168.0", "10.0.0", "172.16.0"
    $vmBaseIpNo = Select-ReadDefault $vmBaseIpList "Please enter a Target Ip Area" 0

    $initBaseIp = Read-HostDefault "Please enter a preset IP address of installed ${baseOsName}" 251
    $vmBaseIp=${vmBaseIpList}[${vmBaseIpNo}] + "." + ${initBaseIp}

    $ipOctetA, $ipOctetB, $ipOctetC = ${vmBaseIpList}[${vmBaseIpNo}].split(".")

    Write-Host "Enter the IP address separated by 4 octet fields"
    Write-Host "Ex) 10 .  1.  0.  1"
    Write-Host "      A.  B.  C.  D"

    $ipOctetA = Read-HostDefault "Please enter a A Octet Field" $ipOctetA
    $ipOctetB = Read-HostDefault "Please enter a B Octet Field" $ipOctetB
    $ipOctetC = Read-HostDefault "Please enter a C Octet Field" $ipOctetC
    $ipOctetD = Read-HostDefault "Please enter a D Octet Field" 1

    $dns1 = ${vmBaseIpList}[${vmBaseIpNo}] + ".1"
    $dns2 = ${vmBaseIpList}[${vmBaseIpNo}] + ".2"
    $gatewayIp = ${vmBaseIpList}[${vmBaseIpNo}] + ".1"

    If ($baseOsName -match "Ubuntu") {
        $prefix = Read-HostDefault "Please enter a prefix" "24"

        $dns = Read-HostDefault "Please enter a DNS IP Address" ${dns1}
    } Else {
        $netmask = Read-HostDefault "Please enter a netmask" "255.255.255.0"

        $dns1 = Read-HostDefault "Please enter a DNS1 IP Address" ${dns1}
        $dns2 = Read-HostDefault "Please enter a DNS2 IP Address" ${dns2}
    }

    $gatewayIp = Read-HostDefault "Please enter a Gateway IP Address" ${gatewayIp}
    $search = Read-HostDefault "Please enter a Search Domain" "online9.com"

    Write-Host "Enter the Vm and Host Name Pattern"
    Write-Host "Ex) The number of Vm : 4"
    Write-Host "    VM name Pattern : kube%{seq}-node => kube1-node, kube2-node, kube3-node, kube4-node"
    Write-Host "    VM name Pattern : kube-node%{seq} => kube-node1, kube-node2, kube-node3, kube-node4"

    $vmNameTemplate = Read-HostDefault "Please enter a Hyper-V Vm Name Pattern" "Kube%{seq}"
    $hostNameTemplate = Read-HostDefault "Please enter a OS(Linux/Ubuntu) Hostname Pattern" "kube-node%{seq}"

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

$addAnsibleHostOptions = ${addAnsibleHostOptions} -creplace ":", "="

Write-Host " "
Write-Host -ForegroundColor Yellow "New VMs are created by copying the selected template VM."
Write-Host -ForegroundColor Yellow "Process              : ${processorCount}"
Write-Host -ForegroundColor Yellow "Memory               : ${vmMemorySize}GB"
Write-Host -ForegroundColor Yellow "Vm Generation        : ${vmGeneration}"
Write-Host -ForegroundColor Yellow "Switch               : ${switchName}"

If ($baseOsName -match "Ubuntu") {
    Write-Host -ForegroundColor Yellow "NETMASK              : ${netmask}"
    Write-Host -ForegroundColor Yellow "DNS1                 : ${dns1}"
    Write-Host -ForegroundColor Yellow "DNS2                 : ${dns2}"
} Else {
    Write-Host -ForegroundColor Yellow "PREFIX               : ${prefix}"
    Write-Host -ForegroundColor Yellow "DNS                  : ${dns}"
}

Write-Host -ForegroundColor Yellow "MTU                  : ${mtu}"
Write-Host -ForegroundColor Yellow "Search Domain        : ${search}"
Write-Host -ForegroundColor Yellow "Vm Folder            : ${targetVmPath}"

If ($targetDiskPath -NE "NONE") {
  Write-Host -ForegroundColor Yellow "Etc Hdd Size         : ${targetDiskSize}GB"
}

Write-Host -ForegroundColor Yellow "User                 : ${user}"

If ($addAnsibleHost -EQ "yes") {
    Write-Host -ForegroundColor Yellow "Ansible Host file    : ${addAnsibleHostPath}/${addAnsibleHostFile}"
    Write-Host -ForegroundColor Yellow "Ansible Host Group   : ${addAnsibleHostGroup}"
    Write-Host -ForegroundColor Yellow "Ansible Host Options : ${addAnsibleHostOptions}"
}

Write-Host -ForegroundColor Yellow "==============================================================="

[int]$ipOctet1=$ipOctetA
[int]$ipOctet2=$ipOctetB
[int]$ipOctet3=$ipOctetC
[int]$ipOctet4=$ipOctetD

$targetOsVersion = ${baseOsName}.split("-")[1]
$baseVhdxName = "${vmBasePath}\${baseOsName}\Virtual Hard Disks\${baseOsName}.vhdx"

For ($i = 1; $i -le $totalVm; $i++) {
    $vmName = ${vmNameTemplate} -creplace "%{seq}", $i
    $vmName = "${vmName}-${targetOsVersion}"
    $vmIp = "${ipOctet1}.${ipOctet2}.${ipOctet3}.${ipOctet4}"

    Write-Host -ForegroundColor Yellow "${targetVmPath}\${vmName}, Ip Address : ${vmIp}"

    If ($ipOctet4 -eq 254) {
        $ipOctet4 = 1

        $ipOctet3 += 1

        If ($ipOctet3 -eq 254) {
            $ipOctet3 = 0
            $ipOctet2 += 1
        }
    }

    $ipOctet4 += 1
}

$isProceed = Read-HostDefault "Do you want to create new Vms" "Yes"

If ($isProceed -ne "Yes") {
    Exit
}

$StartTime = $(get-date)
[int]$ipOctet1=$ipOctetA
[int]$ipOctet2=$ipOctetB
[int]$ipOctet3=$ipOctetC
[int]$ipOctet4=$ipOctetD

If (!(Test-Path ${baseVhdxName})) {
    Write-Host -ForegroundColor Red "${baseVhdxName} file not found..... "
    Exit
}

For ($i = 1; $i -le $totalVm; $i++) {
    $vmName = ${vmNameTemplate} -creplace "%{seq}", $i
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
            Write-Host -ForegroundColor Green "${vmName} Vm is set to use dynamic memory allocation(StartupBytes : ${dynamicStartupBytes}MB , MinimumBytes : ${dynamicMinimumBytes}MB, MaximumBytes : ${dynamicMaximumBytes}MB). "
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
        ping ${vmBaseIp}
    }

    $vmIp = "${ipOctet1}.${ipOctet2}.${ipOctet3}.${ipOctet4}"
    $hostName = ${hostNameTemplate} -creplace "%{seq}", $i
    $copyShell = "scp shell/" + $resetShellFile + " $user@${vmBaseIp}:~/" + $resetShellFile
    $resetShell = "ssh $user@${vmBaseIp} 'chmod 755 ~/${resetShellFile}; ~/${resetShellFile} --host=${hostName} --ip=${vmIp} --gw=${gatewayIp} --netmask=${netmask} --dns1=${dns1} --dns2=${dns2} --search=${search}' "

    SshCopyId $user $vmBaseIp $password
    ExecuteSshShell $user $vmBaseIp $password $copyShell
    ExecuteSshShell $user $vmBaseIp $password $resetShell

    Write-Host -ForegroundColor Red "Wait 5 seconds and Stop ${vmName} Vm"
    Start-Sleep -s 5
    Stop-VM -Name ${vmName}

    Write-Host -ForegroundColor Green "Restart ${vmName}"
    Start-VM -Name ${vmName}

    If ($ipOctet4 -eq 254) {
        $ipOctet4 = 1

        $ipOctet3 += 1

        If ($ipOctet3 -eq 254) {
            $ipOctet3 = 0
            $ipOctet2 += 1
        }
    }

    $ipOctet4 += 1
    Write-Host -ForegroundColor Red "Wait 10 seconds and ReStart ${vmName} Vm"
    Start-Sleep -s 10

    ping ${vmIp}
}

$elapsedTime = $(get-date) - $StartTime
Write-Host -ForegroundColor Yellow "ElapsedTime : ${elapsedTime}"