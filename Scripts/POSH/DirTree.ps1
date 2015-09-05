$var = $post.arg1
$content = gci $var -recurse | select name | convertto-json
$global:message = $content