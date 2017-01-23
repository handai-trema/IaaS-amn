<?php
if(isset($_GET['url']) && preg_match('/^http(s)?:/',$_GET['url'])){
  $url = $_GET['url'];
  $data = array(
      'pattern' => 'htmlspe',
      'show' => 'quickref',
  );
  $options = array('http' => array(
      'method' => 'POST',
      'content' => http_build_query($data),
  ));
  echo file_get_contents($url, false, stream_context_create($options));
}
?>