#KEEP THIS NEXT LINE, ONLY CHANGE IP:PORT, NO SPACES#
#IPPORT=192.168.1.64:8880

cd $path
switch -regex ($GET){

	'/admin' 	{$global:response.ContentType = 'text/html' ; $global:message = $(gc $path/web/admin.html)}
	'/hello' 	{$global:response.ContentType = 'text/html' ; $global:message = "world"};
	default	{
	
				$split = ($post.register).split(",")[0]
				$ModuleCfg = gc ./configs/module.cfg | ? {$_ -notmatch $("$split" + ",")}
				$ModuleCfg += $($post.register)
				$ModuleCfg > ./configs/module.cfg
				$global:message = $($post.register)

				if (!$global:message){$global:message = "Invalid input. You may not be authorized to view this page. Please exit, a log has been saved regarding these actions."}
			} 
}
Get-Variable * | % {$("$($_.name)" + " = " + "$($_.value)")} >> ./logs\debugAgraliSubBroker.log	
		
