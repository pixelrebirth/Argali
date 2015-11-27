$content = invoke-restmethod "http://es.pixelrebirth.local:9200/$($esConfig.mixJobs)/$($post.arg1)"
$global:message = $content._source | convertto-json