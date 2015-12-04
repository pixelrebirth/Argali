$content = invoke-restmethod "http://$($esConfig.esServer)/$($esConfig.mixJobs)/$($post.arg1)"
$global:message = $content._source | convertto-json