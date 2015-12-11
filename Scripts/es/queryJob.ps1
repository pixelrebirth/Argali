$content = invoke-restmethod "$($esConfig.esServer)/$($esConfig.mixJobs)/$($post.arg1)"
$global:message = $content._source | convertto-json