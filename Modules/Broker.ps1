#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#Broker=192.168.1.147:8880
#IPPORT=192.168.1.147:8880
#IPType=Standard

cd $path

switch -regex ($GET){

	'/admin' 	{$global:response.ContentType = 'text/html' ; $global:message = $(gc $path/web/admin.html)}
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
							$global:message = (invoke-restmethod "https://$IPPORTModule/" -method POST -body "codeset=$($POST.codeset)&arg1=$($POST.arg1)" -timeoutsec 1000).outerxml
						}		
					}
				}
	default		{
					$Mime = $(("$get").replace("https://192.168.1.147:8880/",""))
					switch -regex ($Mime){
								
							'.js'	{$global:response.ContentType = 'text/javascript'}
							'.css'	{$global:response.ContentType = 'text/css'}
							'.html'	{$global:response.ContentType = 'text/html'}

					}
					$global:message = $(gc $path/$Mime)
				}
}
if (!$global:message){$global:message = "Invalid input, !message."}
Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} > ./logs\debugAgraliSubBroker.log	