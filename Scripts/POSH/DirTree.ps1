$var = $post.arg1
$xml = gci $var | convertto-xml
$global:message = $xml.outerxml