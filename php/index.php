<?php
if(isset($_GET['url']) && preg_match('/^http(s)?:/',$_GET['url'])){
  $url = $_GET['url'];
  if(isset($_GET['con_name'])){
    $data = array(
        'name' => $_GET['con_name'],
        'user_name' => $_SERVER["REMOTE_ADDR"]
    );
  }
  else{
   $data = array(
       'user_name' => $_SERVER["REMOTE_ADDR"]
   );
  }
  $options = array('http' => array(
      'method' => 'POST',
      'content' => json_encode($data),
      'header' => "Content-Type: application/json\r\n".
      	          "Accept: application/json\r\n"
  ));
  echo file_get_contents($url, false, stream_context_create($options));
}