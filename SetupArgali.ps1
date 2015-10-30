function Use-RunAs {
    param([Switch]$Check)
    
    $IsAdmin = ([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")
    return $IsAdmin
}

function Grant-LogOnAsService{
    param($username)
    
    #Get list of currently used SIDs 
    secedit /export /cfg tempexport.inf 
    $curSIDs = Select-String .\tempexport.inf -Pattern "SeServiceLogonRight" 
    $Sids = $curSIDs.line 
    $sidstring = ""
    $objUser = New-Object System.Security.Principal.NTAccount($username)
    $strSID = $objUser.Translate([System.Security.Principal.SecurityIdentifier])
    if(!$Sids.Contains($strSID) -and !$sids.Contains($username)){
        $sidstring += ",*$strSID"
    }
    if($sidstring){
        $newSids = $sids + $sidstring
        Write-Host "New Sids: $newSids"
        $tempinf = Get-Content tempexport.inf
        $tempinf = $tempinf.Replace($Sids,$newSids)
        Add-Content -Path tempimport.inf -Value $tempinf
        secedit /import /db secedit.sdb /cfg ".\tempimport.inf" 
        secedit /configure /db secedit.sdb 
 
        gpupdate /force 
    }
    else{
        Write-Host "No new sids"
    }
 
    del ".\tempimport.inf" -force -ErrorAction SilentlyContinue
    del ".\secedit.sdb" -force -ErrorAction SilentlyContinue
    del ".\tempexport.inf" -force
}

Function New-Password {
    param ($length)
    $set    = "abcdefghijklmnopqrstuvwxyz0123456789".ToCharArray()
    $result = ""
    for ($x = 0; $x -lt $Length; $x++) {
        $result += $set | Get-Random
    }
    return $result
}

Function Set-LocalServiceAcctCreds {
    param (
        [string]$ServiceName,
        [string]$newAcct,
        [string]$newPass
    )

    $newAcct = ".\" + $newAcct
    $computername = $env:computername
    $filter = 'Name=' + "'" + $ServiceName + "'" + ''
    $service = Get-WMIObject -computername $computername -namespace "root\cimv2" -class Win32_Service -Filter $filter
    $service.Change($null,$null,$null,$null,$null,$null,$newAcct,$newPass)
    $service.StopService()
    while ($service.Started){
        sleep 2
        $service = Get-WMIObject -ComputerName $computername -namespace "root\cimv2" -class Win32_Service -Filter $filter
    }
    $service.StartService()
}

function Add-NewUserToAdminGroup {
    param ($username,$password)
    
    $computername = $env:computername
    $username = $username
    $password = $password
    $desc = 'Automatically created Argali admin account'

    $computer = [ADSI]"WinNT://$computername,computer"
    $computer.delete("user",$username)

    $user = $computer.Create("user", $username)
    $user.SetPassword($password)
    $user.Setinfo()
    $user.description = $desc
    $user.setinfo()
    $user.UserFlags = 65536
    $user.SetInfo()
    $group = [ADSI]("WinNT://$computername/administrators,group")
    $group.add("WinNT://$username,user")
}

if (-not (Use-RunAs -check)){"Please run as administrator..." ; read-host Exit; break}

$null > ./configs/module.cfg
stop-service argali -confirm:$false

.\_ArgaliSRC\Argali.exe install Argali powershell -executionpolicy bypass "$pwd\_ArgaliSRC\argali.ps1"

$password = new-password 30

Add-NewUserToAdminGroup ArgaliSVC $password
Grant-LogOnAsService ArgaliSVC
Set-LocalServiceAcctCreds Argali ArgaliSVC $password

if (-not ($env:path -match "Argali")){
    $newPath= $((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path)+";$pwd\_ArgaliSRC"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}
gci -recurse $pwd | unblock-file

$broker = "notEmpty"
$module = "notEmpty"
while ($broker -ne "" -OR $module -ne ""){
    $broker = read-host Press Enter to install the broker or type anything and enter to bypass broker install
    $module = read-host Press Enter to install a module or type anything and enter to bypass module install
}

[ipaddress]$brokerIP = read-host "What is the IP of the broker server (could be this server)"
[int]$brokerPort = read-host "What is the listening broker port number"

if (!$broker){
    $brokerScript = gc ./install/broker.ps1
    $brokerScript = $brokerScript.Replace('Broker=<ip>:<port>',"Broker=$($brokerIP):$($brokerPort)")
    $brokerScript = $brokerScript.Replace('IPPORT=<ip>:<port>',"IPPORT=$($brokerIP):$($brokerPort)")
    $brokerScript > ./modules/broker.ps1

    $adminPage = gc ./install/admin.html
    $adminPage = $adminPage.replace('action="https://<IP>:<PORT>/api">',"action=`"https://$($brokerIP):$($brokerPort)/api`">")
    $adminPage > ./web/admin.html
}
if (!$module){
    [ipaddress]$moduleIP = read-host "What is the IP of the module server (could be this server)"
    [int]$modulePort = read-host "What is the listening module port number"

    $moduleScript = gc ./install/module.ps1
    $moduleScript = $moduleScript.Replace('Broker=<ip>:<port>',"Broker=$($brokerIP):$($brokerPort)")
    $moduleScript = $moduleScript.Replace('IPPORT=<ip>:<port>',"IPPORT=$($moduleIP):$($modulePort)")
    $moduleName = read-host what is the module name
    $moduleScript > $("./modules/$moduleName" + ".ps1")
}

read-host Close all powershell and cmd sessions and start Argali service

get-service Argali | start-service -confirm:$false
get-process *cmd* | stop-process -force
get-process *powershell* | stop-process -force