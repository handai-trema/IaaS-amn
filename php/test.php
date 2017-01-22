<?php
$_GET['url'] = 'http://localhost:9292/api/status';
if(isset($_GET['url']) && preg_match('/^http(s)?:/',$_GET['url'])){
    echo file_get_contents($_GET['url']);
}
?>