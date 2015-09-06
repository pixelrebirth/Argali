$var = $post.arg1
$content = gci $var | select name,mode,attributes | convertto-json
$global:message = $content