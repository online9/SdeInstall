param ($serverIp, $shell, $user='root', $shellPath='~', $options="", $verbose="", $copyShell="yes")

Function Show-Help() {
    Write-Host 'NAME'
    Write-Host '    Ssh-Shell Executor'
    Write-Host ''
    Write-Host 'SYNOPSIS'
    Write-Host '    ssh shell execute powershell'
    Write-Host ''
    Write-Host 'SYNTAX'
    Write-Host '    SshShell.ps1 -serverIp <ServerIp> -shell <ShellPathAndFile> [-user <User> -shellPath <RemoteShellPath> -options "<Options>"]'
    Write-Host ''
    Write-Host 'DESCRIPTION'
    Write-Host '    ssh (SSH client) is a program for logging into a remote machine and for executing commands on a remote machine.'
    Write-Host '    It is intended to provide secure encrypted communications between two untrusted hosts over an insecure network.'
    Write-Host '    X11 connections, arbitrary TCP ports and UNIX-domain sockets can also be forwarded over the secure channel.'
    Write-Host '    SshShell is a powershell script for executing commands on a remote machine using ssh.'
    Write-Host ''
    Write-Host 'Examples'
    Write-Host '    SshShell.ps1 -help'
    Write-Host '    SshShell.ps1 -serverIp 172.18.0.1'
    Write-Host '    SshShell.ps1 -serverIp 172.18.0.1 -user root'
    Write-Host '    SshShell.ps1 -serverIp 172.18.0.1 -user root -shell installAnsible.sh'
    Write-Host '    SshShell.ps1 -serverIp 172.18.0.1 -user root -shell installAnsible.sh -shellPath /sde/cloud/shell'
    Write-Host '    SshShell.ps1 -serverIp 172.18.0.1 -user root -shell installAnsible.sh -shellPath /sde/cloud/shell -options --inventory=sde-support.inv,--playbook=sdeEnv/main.yml,--options=targetServers=all'
    Write-Host ''
}

If (($serverIp -EQ $Null -AND -$Args.Count -EQ 0) -OR ($Args[0] -MATCH "-h" -OR $Args[0] -MATCH "-help")) {
    Show-Help
    Exit
}

$localStartTime = $(get-date)
$shellFile = (Get-Item $shell).Basename
$extension = (Get-Item $shell).Extension
$localShellPath = (Get-Item $shell).DirectoryName

Write-Host -ForegroundColor Green "Ssh shell execute configuration(${serverIp})"
Write-Host -ForegroundColor Green "======================================================================="
Write-Host -ForegroundColor Green "Operation User                        : ${user}"
Write-Host -ForegroundColor Green "Server Ip                             : ${serverIp}"
Write-Host -ForegroundColor Green "-----------------------------------------------------------------------"
Write-Host -ForegroundColor Green "Local Shell Path                      : ${localShellPath}"
Write-Host -ForegroundColor Green "Shell File Name                       : ${shellFile}${extension}"
Write-Host -ForegroundColor Green "Remote Shell Path                     : ${shellPath}"
Write-Host -ForegroundColor Green "-----------------------------------------------------------------------"
Write-Host -ForegroundColor Green "Options                               : ${options}"
Write-Host -ForegroundColor Green "Verbose                               : ${verbose}"
Write-Host ""

If ($copyShell.toLower() -EQ "yes") {
    Write-Host -ForegroundColor Green "ssh -o StrictHostKeyChecking=no ${user}@${serverIp} mkdir -p ${shellPath}"
    ssh -o StrictHostKeyChecking=no ${user}@${serverIp} "mkdir -p ${shellPath}"

    Write-Host -ForegroundColor Green "scp -o StrictHostKeyChecking=no ${localShellPath}/${shellFile}${extension} ${user}@${serverIp}:${shellPath}/${shellFile}${extension}"
    scp -o StrictHostKeyChecking=no ${localShellPath}/${shellFile}${extension} ${user}@${serverIp}:${shellPath}/${shellFile}${extension}
}

If ($verbose -EQ "") {
    Write-Host -ForegroundColor Green "ssh -o StrictHostKeyChecking=no ${user}@${serverIp} chmod 775 ${shellRemotelPath}/${shellFile}${extension}; ${shellPath}/${shellFile}${extension} ${options}"
    ssh -t -o StrictHostKeyChecking=no ${user}@${serverIp} "chmod 775 ${shellPath}/${shellFile}${extension}; ${shellPath}/${shellFile}${extension} ${options}"
} Else {
    Write-Host -ForegroundColor Green "ssh -o StrictHostKeyChecking=no ${user}@${serverIp} chmod 775 ${shellRemotelPath}/${shellFile}${extension}; ${shellPath}/${shellFile}${extension} ${options} --verbose=${verbose}"
    ssh -t -o StrictHostKeyChecking=no ${user}@${serverIp} "chmod 775 ${shellPath}/${shellFile}${extension}; ${shellPath}/${shellFile}${extension} ${options} --verbose=${verbose}"
}

$elapsedTime = $(get-date) - $localStartTime
Write-Host -ForegroundColor Green '-----------------------------------------------------------------------------------'
Write-Host -ForegroundColor Green "SshShell ${shellPath}/${shellFile}${extension} ElapsedTime : ${elapsedTime}"
Write-Host -ForegroundColor Green '-----------------------------------------------------------------------------------'
