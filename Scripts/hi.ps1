$var = $post.arg1
$xml = "hi $var" | convertto-xml
$global:message = $xml.outerxml
