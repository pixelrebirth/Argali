#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#Broker=<ip>:<port>
#IPPORT=<ip>:<port>
#IPType=Standard

$error.clear()

$esConfig = gc -raw ./configs/elasticConfig.json | convertfrom-json
$timerWait = 6000

$foldername = $MyInvocation.MyCommand.Name.split(".")[0]
$path = $($("$path/scripts/$foldername/" + "$($Post.codeset)" + ".ps1"))

$command = $Post.arg1 

import-module posh-ssh

$cred = New-Object PSCredential 'root',$('' | ConvertTo-SecureString -AsPlainText -Force)

$ssh = New-SSHSession 10.163.221.181 -credential $cred -AcceptKey
$session = Get-SSHSession -index $ssh.sessionid
$stream = $session.Session.CreateShellStream("dumb", 0, 0, 0, 0, 1000)

# $scriptBlock = [Scriptblock]::Create($(gc -raw $path))
# $jobID = (start-job -scriptBlock $scriptBlock).childjobs
# $state = $jobID.JobStateInfo.state

$startTime = get-date

#remove when you update state methodology
$state = "linux"
$json = "{`"codeSet`": `"$foldername/$($Post.codeset)`",`"startTime`": `"$startTime`"}"
$json > ./logs/json.json
$elasticID = (invoke-restmethod "http://10.163.221.181:9200/$($esConfig.mixJobs)/" -method POST -body $json)._id
$outelasticID = "{`"elasticID`": `"$elasticID`"}"
$global:response.ContentType = 'application/json'
[byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($outelasticID)
$global:response.ContentLength64 = $buffer.length
$global:response.OutputStream.Write($buffer, 0, $buffer.length)
$global:response.Close()

$stream.Write("yum search vim`n")

$json = $null
$json = "{`"codeSet`": `"$foldername/$($Post.codeset)`",`"startTime`": `"$startTime`",`"output`": [`""
foreach ($line in ($stream.Read() -split ("`n"))){
    $Line = $Line.substring(0,$Line.length-1).trim()
    $line >> ./logs/json.json
    $json += "$Line"+"Aw3s0m3"
}
$json = $json + "`"]}"
$json >> ./logs/json.json
invoke-restmethod "http://10.163.221.181:9200/$($esConfig.mixJobs)/$elasticID" -method POST -body $(ConvertTo-ElasticJson $json)

# $state = $jobID.JobStateInfo.state
$error > ./logs/output.log

$json = $json.substring(0,$json.length-1) + ", `"endTime`": `"$(get-date)`"}"
invoke-restmethod "http://10.163.221.181:9200/$($esConfig.mixJobs)/$elasticID" -method POST -body $(ConvertTo-ElasticJson $json)
$json >> ./logs/json.json