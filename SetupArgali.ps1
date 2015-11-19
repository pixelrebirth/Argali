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
    $result = $result + "!P"
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

$erroractionpreference = 0
if (-not (Use-RunAs -check)){"Please run as administrator..." ; read-host Exit; break}

"#This line is intentional" > ./configs/module.cfg
"#This line is also intentional" >> ./configs/module.cfg
stop-service argali -confirm:$false
mkdir $pwd\modules

.\_ArgaliSRC\Argali.exe install Argali powershell -executionpolicy bypass "$pwd\_ArgaliSRC\argali.ps1"

$password = new-password 30

Add-NewUserToAdminGroup ArgaliSVC $password
Grant-LogOnAsService ArgaliSVC
Set-LocalServiceAcctCreds Argali ArgaliSVC $password

$currentPath= $((Get-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH).Path)

if (-not ($currentPath -match "Argali")){
    $newPath = "$currentPath" + ";$pwd\_ArgaliSRC"
    Set-ItemProperty -Path 'Registry::HKEY_LOCAL_MACHINE\System\CurrentControlSet\Control\Session Manager\Environment' -Name PATH -Value $newPath
}
gci -recurse $pwd | unblock-file

$computer = hostname

$brokerIP = (Test-Connection $computer -count 1).ipv4address.ipaddresstostring
$brokerPort = 443

$moduleIP = $brokerIP
$modulePort = 9000

$brokerScript = gc ./install/broker.ps1
$brokerScript = $brokerScript.Replace('Broker=<ip>:<port>',"Broker=$($brokerIP):$($brokerPort)")
$brokerScript = $brokerScript.Replace('IPPORT=<ip>:<port>',"IPPORT=$($brokerIP):$($brokerPort)")
$brokerScript > ./modules/broker.ps1

$adminPage = gc ./install/AdminController.js
$adminPage = $adminPage.replace('<ip>:<port>',"$($brokerIP):$($brokerPort)")
$adminPage > ./web/js/AdminController.js

$moduleScript = gc ./install/module.ps1
$moduleScript = $moduleScript.Replace('Broker=<ip>:<port>',"Broker=$($brokerIP):$($brokerPort)")
$moduleScript = $moduleScript.Replace('IPPORT=<ip>:<port>',"IPPORT=$($moduleIP):$($modulePort)")
$moduleName = "POSH"
$moduleScript > $("./modules/$moduleName" + ".ps1")

read-host Close all powershell and cmd sessions and start Argali service

get-process *cmd* | stop-process -force
restart-service Argali 
get-process *powershell* | stop-process -force