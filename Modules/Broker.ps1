#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#Broker=192.168.1.64:8880
#IPPORT=192.168.1.64:8880
#IPType=Standard

cd $path
switch -regex ($GET){

	'/admin' 	{$global:response.ContentType = 'text/html' ; $global:message = $(gc $path/web/admin.html)}
	'/hello' 	{$global:response.ContentType = 'text/html' ; $global:message = "world"};
	'/register'	{
					if ($($post.register) -ne ""){
						$split = ($post.register).split(",")[0]
						$ModuleCfg = gc ./configs/module.cfg | ? {$_ -notmatch $("$split" + ",")}
						$ModuleCfg += $($post.register)
						$ModuleCfg > ./configs/module.cfg
						$global:message = $($post.register)
					}
				} 
	default 	{	
					$PostModule = gc ./configs/module.cfg | ? {$_ -notmatch "#"}
					foreach ($line in $PostModule) {
				
						$config = $line.split(",")
						$IPPortModule =  "$($config[1])"
						if ($($post.module) -match "$($config[0])") {
							$global:message = (invoke-restmethod "https://$IPPORTModule/" -method POST -body "codeset=$($POST.codeset)&arg1=$($POST.arg1)").outerxml
						}		
					}
				}
}
if (!$global:message){$global:message = "Invalid input, !message."}
Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} >> ./logs\debugAgraliSubBroker.log	
		
