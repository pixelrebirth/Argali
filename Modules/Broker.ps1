#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#Broker=192.168.1.240:8880
#IPPORT=192.168.1.240:8880
#IPType=Standard

cd $path

switch -regex ($GET){

	'/hello' 	{$global:response.ContentType = 'text/html' ; $global:message = "world"};
	'/register'	{
					if (check-registration $($post.register)){
						$splitModule = ($post.register).split(",")[0]
						$ModuleCfg = gc ./configs/module.cfg | ? {$_ -notmatch $("$splitModule" + ",")}
						$ModuleCfg += $($post.register)
						$ModuleCfg > ./configs/module.cfg
						$global:message = $($post.register)
					}
				} 
	'/api' 		{	
					$PostModule = gc ./configs/module.cfg | ? {$_ -notmatch "#"}
					foreach ($line in $PostModule) {
				
						$config = $line.split(",")
						$IPPortModule =  "$($config[1])"
						if ($($post.module) -match "$($config[0])") {
							$global:message = invoke-restmethod "http://$IPPORTModule/" -method POST -body "codeset=$($POST.codeset)&arg1=$($POST.arg1)" -timeoutsec 1000 | convertto-json
							$global:response.ContentType = 'application/json'
						}		
					}
				}
	'/angular'	{
					$global:response.ContentType = 'text/javascript' ; $global:message = $angularCache
				}
	default		{
					switch -regex ($RawMime){
								
							'.js'	{$global:response.ContentType = 'text/javascript'}
							'.css'	{$global:response.ContentType = 'text/css'}
							'.html'	{$global:response.ContentType = 'text/html'}
							'.jpg'	{$global:response.ContentType = 'image/jpeg'}
							'.png'	{$global:response.ContentType = 'image/png'}
							'.json'	{$global:response.ContentType = 'application/json'}
					}
					$global:message = [byte[]] $(Get-ContentBytes -path "$path/web$RawMime")
				}
}
if (!$global:message){$global:message = "Invalid input, !message."}
Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} > ./logs\debugAgraliSubBroker.log	