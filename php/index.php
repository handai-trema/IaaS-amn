<?php
$urls = array('http://192.168.1.4:9292/api/','http://192.168.1.4:9292/api/');
#コンテナを作成
if (isset($_GET['con_name'])) {
  $ip_addr_infs = file('../VM/ip_table.txt');
  foreach ($ip_addr_infs as $idx => $ip_addr_inf) {
    $used_flag = split(",",$ip_addr_inf)[1];
    #コンテナの作成
    if ($used_flag == "f"){
      #コンテナのip
      $ip_addr = split(",",$ip_addr_inf)[0];
      $url = $urls[rand(0,1)].'create_container';
      $data = array(
          'name' => $_GET['con_name'],
          'ip_addr' => $ip_addr,
          'user_ip_addr' => $_SERVER["REMOTE_ADDR"]
      );
      $options = array('http' => array(
          'method' => 'POST',
          'content' => json_encode($data),
          'header' => "Content-Type: application/json\r\n".
          	          "Accept: application/json\r\n"
      ));
      #REST_APIを叩いてコンテナを作成
      file_get_contents($url, false, stream_context_create($options));
      #上書き
      $ip_addr_infs[$idx] = $ip_addr.',t,'.$_GET['con_name'].','.$_SERVER["REMOTE_ADDR"]."\n";
      echo $ip_addr_infs[$idx];
      break;
    }
  }
  file_put_contents('../VM/ip_table.txt',$ip_addr_infs);
}
#コンテナの情報を表示
else if (isset($_GET['show'])) {
  $ip_addr_infs = file('../VM/ip_table.txt',FILE_IGNORE_NEW_LINES);
  $user_container_infs = array();
  foreach($ip_addr_infs as $ip_addr_inf){
    $user_name = split(",",$ip_addr_inf)[3];
    echo "user_name:".$user_name."\n";
    echo "server:".$_SERVER["REMOTE_ADDR"]."\n";
    echo ($user_name == $_SERVER["REMOTE_ADDR"]);
    echo "\n";
    if ($user_name == $_SERVER["REMOTE_ADDR"]) {
      array_push($user_container_infs, $ip_addr_inf);
    }
  }
  echo implode("\n ",$user_container_infs);
}
