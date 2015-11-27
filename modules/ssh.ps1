#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#Broker=192.168.1.245:443
#IPPORT=192.168.1.245:9001
#IPType=Standard

$foldername = $MyInvocation.MyCommand.Name.split(".")[0]
$path = $($("$path/scripts/$foldername/" + "$($Post.codeset)" + ".ps1"))

$json = "{`"startTime`": `"$((get-date).datetime)`"}"
$esID = (invoke-restmethod "http://es.pixelrebirth.local:9200/argali/POSHtest/" -method POST -body $json)._id
$json = $json.substring(0,$json.length-1) + ",`"output`": [" 

$outEsId = "{`"esID`": `"$esID`"}"
$global:response.ContentType = 'application/json'
[byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($outEsId)
$global:response.ContentLength64 = $buffer.length
$global:response.OutputStream.Write($buffer, 0, $buffer.length)
$global:response.Close()

$scriptBlock = [Scriptblock]::Create($(gc -raw $path))
$jobID = start-job -scriptBlock $scriptBlock
$state = $jobID.state

while ($state -eq "Running"){
    $receiveJob = receive-job $jobID
    if ($receiveJob -ne $null){
        foreach ($jsonObject in $receiveJob){
            $json += "{`"resultLine`": `"$jsonObject`"},"
            $jsonOutput = $json.substring(0,$json.length-1) + "]}"
            invoke-restmethod "http://es.pixelrebirth.local:9200/argali/POSHtest/$esID" -method POST -body $jsonOutput
        }
    }
    start-sleep -milliseconds 300
    $state = $jobID.state
}

$json = $jsonOutput.substring(0,$jsonOutput.length-1) + ", `"endTime`": `"$((get-date).datetime)`"}"
invoke-restmethod "http://es.pixelrebirth.local:9200/argali/POSHtest/$esID" -method POST -body $json
