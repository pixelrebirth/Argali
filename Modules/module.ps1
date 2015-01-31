#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#Broker=192.168.1.64:8880
#IPPORT=192.168.1.64:8881
#IPType=Standard

#This code starts the runtime environment for the script code, so the modules and pre-requisites can be established in the service loop
import-module Microsoft.PowerShell.Management

#This code creates a message out of the results of the script and hands it back to the Argali service loop / broker
& $($("$path/scripts/" + "$($Post.codeset)" + ".ps1"))
if (!$global:message){$global:message = "SubScript Invalid or Null"}		
Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} > ./logs\debugAgraliSubModule.log	