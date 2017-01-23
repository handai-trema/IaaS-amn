<?php
if(isset($_GET['url']) && preg_match('/^http(s)?:/',$_GET['url'])){
  $url = $_GET['url']."/".$_SERVER["REMOTE_ADDR"];
  $data = array(
      'pattern' => 'htmlspe',
      'show' => 'quickref',
  );
  $options = array('http' => array(
      'method' => 'POST',
      'content' => http_build_query($data),
  ));
  file_get_contents($url, false, stream_context_create($options));
  echo $_SERVER["REMOTE_ADDR"];
}