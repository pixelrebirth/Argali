#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#Broker=<ip>:<port>
#IPPORT=<ip>:<port>
#IPType=Standard

$foldername = $MyInvocation.MyCommand.Name.split(".")[0]

& $($("$path/scripts/$foldername/" + "$($Post.codeset)" + ".ps1"))
if (!$global:message){$global:message = "SubScript Invalid or Null"}		
# Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} > ./logs\debugAgraliSubModule.log
