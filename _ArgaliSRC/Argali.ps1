cd ($env:path.split(";") | ? {$_ -match "argali"})
cd ..

import-module ./libraries/Argali_library.psm1
[int]$moduleNum = 0

Foreach ($module in $(gci ./modules/*.ps1)){
	
	$moduleNum++
	
	$IPPort = (gc $module | ? {$_ -match "#IPPORT"}).replace("#IPPORT=","")
	Set-SSLCertificate $IPPort

	new-variable Listener$($moduleNum) -value (New-Object System.Net.HttpListener)
	$(get-variable Listener$($moduleNum)).value.Prefixes.Add("http://$IPPORT/") 
	
	$(get-variable Listener$($moduleNum)).value.Start()

	$Thread = 1
	$MaxThread = ($(Get-WmiObject win32_computersystem).NumberOfLogicalProcessors) * 2

	$path = $((get-location).path)
	
	$ScriptBlock = `
	{
		Param($Listener, $Path, $Module)
		cd $path
		
		import-module ./libraries/Argali_library.psm1

		Set-Crypto | out-null

		$angularCache =  $(gc -raw -path $path/web/js/angular.js -encoding utf8)
		
		while ($true){
			
			[System.GC]::Collect()
			
			$Context = $Listener.GetContext()
			$Response = $Context.Response
			$Response.Headers.Add("X-Powered-By","Argali")

			$Request = $Context.Request
			$InputStream = $Request.InputStream
			$ContentEncoding = $Request.ContentEncoding
			
			#Check-Session $($request | select headers)
			
			$RawMime = $request.RawUrl
			$GET = $Request.Url
			$POST = Get-POST -InputStream $InputStream -ContentEncoding $ContentEncoding
			$message = $null
			
			& $module
						
			if ($message -isnot [byte[]]){[byte[]] $buffer = [System.Text.Encoding]::UTF8.GetBytes($message)}
			if ($message -is [byte[]]){[byte[]] $buffer = $message}
			$response.ContentLength64 = $buffer.length
			$response.OutputStream.Write($buffer, 0, $buffer.length)

			$Response.Close()
			
			$message = $null
			$Response = $null
			[System.GC]::Collect()
			Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} > ./logs\debugAgraliIn.log
			
		}
	}
		
	while ($Thread -le $MaxThread){
		
		$pipeline  = [System.Management.Automation.PowerShell]::create()
		$Pipeline.AddScript($ScriptBlock)
		$Pipeline.AddArgument($((get-variable Listener$($moduleNum)).value))
		$Pipeline.AddArgument($path)
		$Pipeline.AddArgument($module)
		$Pipeline.BeginInvoke()
		$Thread++	
		
		[System.GC]::Collect()
	}
	
}

Set-Crypto | out-null
Foreach ($module in $(gci ./modules/*.ps1)){
	$IPType = (gc $module | ? {$_ -match "#IPType"}).replace("#IPType=","")
	$IPPort = (gc $module | ? {$_ -match "#IPPORT"}).replace("#IPPORT=","")
	$IPBroker = (gc $module | ? {$_ -match "#Broker"}).replace("#Broker=","")
	Invoke-restmethod -uri https://$IPBroker/register -method post -body $("register=$($module.basename)" + ",$ipport,$iptype")
	$("register=$($module.basename)" + ",$ipport,$iptype") >> ./logs/register.log
}
	
$error >> ./logs\debugAgraliError.log
Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} > ./logs\debugAgraliOut.log
while ($true) {$pipeline.streams.error > ./logs\debugAgraliError.log ; start-sleep 30}