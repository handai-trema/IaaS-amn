## 課題 (スライス機能の拡張)

* スライスの分割・結合
  * スライスの分割と結合機能を追加する
* スライスの可視化
  * ブラウザでスライスの状態を表示
* REST APIの追加
  * 分割・統合のできるAPIを追加


## 解答

###提出者
* 木籐
* 銀杏
* 永富
* 錦織
* 村上


### スライスの分割

[./bin/slice](https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/bin/slice)に変更を加えた。


以下に変更を加えた箇所を示す

```
  desc 'Split a virtual slice'
  arg_name 'name'
  command :split do |c|
    c.desc 'Location to find socket files'
    c.desc 'MAC address'
    c.flag [:m, :mac]
    c.desc 'Switch port'
    c.flag [:p, :port]
    c.desc 'Slice name'
    c.flag [:s, :slice]
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      DRb.start_service
      fail 'slice name is required.' if args.empty?
      #slice_new = args[0]
      #slice_a = args[1]
      #slice_b = args[2]
      controller = Trema.trema_process('RoutingSwitch', options[:socket_dir]).controller
      #slice_new = slice(options[:socket_dir]).create(args[0])
      slice_set = nil
      while !(slice_set == 'end') do
        puts "Input slice name= \n"
        slice_set = STDIN.gets.to_s.chomp
        if !(slice_set == 'end') then
          slice_new = slice(options[:socket_dir]).create(slice_set)
          host = nil
          while !(host == 'end') do 
            puts "Input host name= \n"
            host = STDIN.gets.to_s.chomp
            slice(options[:socket_dir]).all.each do |slice|
              if slice.name == args[0] then
                slice.each do |port, mac_addresses|
                  for num in 0 ... mac_addresses.length do
                    if mac_addresses[0] == host then
                      puts "nagatomi"///消す予定
                      slice_new.add_port(dpid: port.fetch(:dpid), port_no: port.fetch(:port_no))
                      slice_new.add_mac_address(host,
                                                dpid: port.fetch(:dpid),
                                                port_no: port.fetch(:port_no))
                    end
                  end
                end
              end
            end
          end
        end
      end
      slice(options[:socket_dir]).destroy(args.first)
      update_slice(options[:socket_dir])
    end
  end
```

####コマンドの実行

以下に示す3つのホストを有するslice5を３つのスライスに分割する。  
```
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice5
  0x4:1
    22:22:22:22:22:22
  0x6:1
    44:44:44:44:44:44
  0x1:1
    11:11:11:11:11:11
```

コマンド入力後、コンソール入力が求められる。引数には分割元のスライスを指定し、新たに分割するスライスの名前→そのスライスに加えるホストのMACアドレスを入力する。
endと入力することでその入力を終了する。
```
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice split slice5
Input slice name= 
slice1
Input host name= 
22:22:22:22:22:22
nagatomi///消す予定
Input host name= (MACアドレスを入力)
end

Input slice name= 
slice2
Input host name= 
44:44:44:44:44:44
nagatomi///消す予定
Input host name= 
end

Input slice name= 
slice3
Input host name= 
11:11:11:11:11:11
nagatomi///消す予定
Input host name= 
end(endとしたら、その入力を終了するようになっている。)

Input slice name= 
end
Input host name= 
end

ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice1
  0x4:1
    22:22:22:22:22:22
slice2
  0x6:1
    44:44:44:44:44:44
slice3
  0x1:1
    11:11:11:11:11:11

```
最終的にもともと同じスライスにあった3つのホストが別々のスライスに分割されていることがわかる。


###スライスの結合

スライスの分割と同様に、[./bin/slice](https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/bin/slice)に変更を加えた。

変更箇所を以下に示す。複数のスライスを一度に結合できるように実装した。
```
  desc 'Merge a virtual slices'
  arg_name 'name1'
  arg_name 'name', :multiple
  command :merges do |c|
    c.desc 'Location to find socket files'
    #c.switch [:into, :slice_divide]
    c.desc 'MAC address'
    c.flag [:m, :mac]
    c.desc 'Switch port'
    c.flag [:p, :port]
    c.desc 'Slice name'
    c.flag [:s, :slice]
    c.flag [:S, :socket_dir], default_value: Trema::DEFAULT_SOCKET_DIR

    c.action do |_global_options, options, args|
      DRb.start_service
      fail 'slice name is required.' if args.empty?
      controller = Trema.trema_process('RoutingSwitch', options[:socket_dir]).controller
      slice_new = slice(options[:socket_dir]).create(args[0])
      slice(options[:socket_dir]).all.each do |slice|
        for num in 1 ... args.length do
          if slice.name == args[num] then
            slice.each do |port, mac_addresses|
              slice_new.add_port(dpid: port.fetch(:dpid), port_no: port.fetch(:port_no))
              mac_addresses.each do |each|
                slice.delete_mac_address(each,
                                         dpid: port.fetch(:dpid),
                                         port_no: port.fetch(:port_no))
                slice_new.add_mac_address(each,
                                          dpid: port.fetch(:dpid),
                                          port_no: port.fetch(:port_no))
                slice.delete_port(dpid: port.fetch(:dpid), port_no: port.fetch(:port_no))       
              end
            end
          end
        end
      end 
      for num in 1 ... args.length do
        slice(options[:socket_dir]).destroy(args[num])
      end
      update_slice(options[:socket_dir])
    end
  end
```

####コマンドの実行

slice1~slice4の4つのスライスを結合し、新しいslice10というスライスを作成した。

slice merges (結合した後のスライス名) ((結合するスライス）...(結合するスライス))

とコマンドを入力することで実行可能。

```
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice1
  0x1:1
    11:11:11:11:11:11
slice2
  0x4:1
    22:22:22:22:22:22
slice3
  0x5:1
    33:33:33:33:33:33
slice4
  0x6:1
    44:44:44:44:44:44
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice merges slice10 slice1 slice2 slice3 slice4
ensyuu2@ensyuu2-VirtualBox:~/sliceable-switch-team-w$ ./bin/slice list
slice10
  0x1:1
    11:11:11:11:11:11
  0x4:1
    22:22:22:22:22:22
  0x5:1
    33:33:33:33:33:33
  0x6:1
    44:44:44:44:44:44

```

以上より、4つのスライスが結合されていることがわかる。

###スライスの可視化
ブラウザ上のスライスの可視化を実装した。
各スライスに対応したボタンを選択すると、選択したスライスに属するホストの背景に色がつき、各スライスに属するホストのMACアドレスが表示される。
allを選択すると全てのスライス情報が表示される。
ここでは、ラジオボタンを用いることで複数の項目にチェックがつかないように実装した。

ラジオボタンの各項目の作成は以下の[javascript/Draw_network.js](https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/javascript/Draw_network.js)中の関数createRadioButtonで実行される。
4行目のfor文の処理によりスライスの数が変動した場合にも対応している。

```
var createRadioButton = function() {
    if (pre_data[0].slices == []) {return}
    var str = '<input id="Radio0" name="RadioGroup1" type="radio" onchange="onRadioButtonChange();" /> <label for="Radio1">all</label><br/>';
    for ( var i = 0; i < pre_data[0].slices.length; i++ ) {
    str = str + '<input id="Radio' + String(i+1) + '" name="RadioGroup1" type="radio" onchange="onRadioButtonChange();" /> <label for="Radio1">' + pre_data[0].slices[i].name + '</label><br/>';
    }
    document.getElementById('radiobutton').innerHTML = '<form name="form1" action="">' + str +  '</form>';
  };
```

ラジオボタンの生成後は下記の関数onRadioButtonChangeで、ラジオボタンの状態確認及びスライスの表示を行う。
3から5行目では、ラジオボタンのon/off状態を配列checkに格納して、ラジオボタンの状態を確認している。
7から17行目では、allを選択した場合のホスト表示処理を行っている。
対して、18から29行目では、各スライスを選択した場合のホスト表示処理を行っている。

```
function onRadioButtonChange() {
  var check = [];
  for (var i = 0; i < pre_data[0].slices.length+1; i++){
    check[i] = eval("document.form1.Radio" + String(i) + ".checked");
  }
  var target = document.getElementById("output");
  if (check[0] == true) {
    var host_s = {};
    for (var i = 0; i < pre_data[0].slices.length; i++){
      for (var j = 0; j < pre_data[0].hosts.length; j++){
        if ($.inArray(pre_data[0].hosts[j].label, pre_data[0].slices[i].host) >= 0){
          nodes.update([{id:pre_data[0].hosts[j].id, image: './html_images/computer_laptop_slice' + String(i+1) +'.png'}]);
        }
      }
    }
        target.innerHTML = JSON.stringify(host_s, null, 4);
  }
  for (var i = 0; i < pre_data[0].slices.length; i++){
    if (check[i+1] == true) {
      for (var j = 0; j < pre_data[0].hosts.length; j++){
        if ($.inArray(pre_data[0].hosts[j].label, pre_data[0].slices[i].host) >= 0){
          nodes.update([{id:pre_data[0].hosts[j].id, image: './html_images/computer_laptop_slice' + String(i+1) +'.png'}]);
        }else{
          nodes.update([{id:pre_data[0].hosts[j].id, image: './html_images/computer_laptop.png'}]);
        }
      }
      target.innerHTML = JSON.stringify(pre_data[0].slices[i].host, null, 4);
    }
  }
};
```

####表示の確認
図1のトポロジを用いて、表示の確認を行った。
図1のトポロジでは、MACアドレスが11:11:11:11:11:11と44:44:44:44:44:44のホストはslice1に属する。
また、MACアドレスが22:22:22:22:22:22と33:33:33:33:33:33のホストはslice2に属する。

|<img src="https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/picture/no_select.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                   図 1 トポロジ画像		                                               |  

はじめにslice1を選択してトポロジを表示した。
図2に表示結果を示す。
slice1に属するMACアドレス11:11:11:11:11:11と44:44:44:44:44:44のホストが赤い背景で色付けされていることが分かる。

|<img src="https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/picture/slice1.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                   図 2 slice1選択時のトポロジ画像                                               |  

次ににslice2を選択してトポロジを表示した。
図3に表示結果を示す。
slice2に属するMACアドレス22:22:22:22:22:22と33:33:33:33:33:33のホストが青い背景で色付けされていることが分かる。

|<img src="https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/picture/slice2.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                   図 3 slice2選択時のトポロジ画像                                               |  

最後にallを選択してトポロジを表示した。
図4に表示結果を示す。
slice1に属するMACアドレス11:11:11:11:11:11と44:44:44:44:44:44のホストが赤い背景で色付けされていることが分かる。
また、slice2に属するMACアドレス22:22:22:22:22:22と33:33:33:33:33:33のホストが青い背景で色付けされていることが分かる。

|<img src="https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/picture/all.png" width="420px">|  
|:------------------------------------------------------------------------------------------------------------:|  
|                                   図 3 slice2選択時のトポロジ画像                                               |  

###REST APIの実装

[lib/rest_api.rb](https://github.com/handai-trema/sliceable-switch-team-w/blob/develop/lib/rest_api.rb)を変更して、APIを用いたスライスのマージを実装した。
下記の部分をrest_api.rbに追加した。

```
  desc 'Merge slices.'
  params do
    requires :new_slice, type: String, desc: 'Slice ID.'
    requires :a_slice, type: String, desc: 'Slice ID.'
    requires :b_slice, type: String, desc: 'Slice ID.'
  end
  post 'slices/:new_slice' do
    rest_api do 
      DRb.start_service#
      Slice.create params[:new_slice]
      puts Slice.find_by!(name: params[:a_slice])
      puts "a", Slice.find_by!(name: params[:a_slice]).ports
      puts Slice.find_by!(name: params[:b_slice])
      puts "b", Slice.find_by!(name: params[:b_slice]).ports
      Slice.find_by!(name: params[:a_slice]).each do |port, mac_addresses|#
        Slice.find_by!(name: params[:new_slice]).add_port(port)
        mac_addresses.each do |mac|
          Slice.find_by!(name: params[:new_slice]).add_mac_address(mac, port)
        end
      end
      Slice.find_by!(name: params[:b_slice]).each do |port, mac_addresses|#
        Slice.find_by!(name: params[:new_slice]).add_port(port)
        mac_addresses.each do |mac|
          Slice.find_by!(name: params[:new_slice]).add_mac_address(mac, port)
        end
      end
      Slice.destroy params[:a_slice]
      Slice.destroy params[:b_slice]
    end
  end
```

2から5行目では、コマンドで与えなくてはならない引数の設定をしている。
APIを用いたスライスの統合では、マージ後のスライス名、マージする2つのスライス名を引数として与える必要がある。
9行目では、マージ後のスライスを作成している。
14行目から25行目では、マージ前のスライスに属するホストをマージ後のスライスに追加している。
26，27行目では、マージ前の2つのスライスを破棄している。

####コマンドの実行

まず、下記のコマンドを実行してtremaによる仮想ネットワークを起動した。
```
ensyuu2@ensyuu2-VirtualBox:~/week8/sliceable-switch-team-w$ ./bin/trema run lirouting_switch.rb -c trema.conf -- --slicing
```

次に、別の端末で下記のコマンドを実行してサーバを起動した。
```
ensyuu2@ensyuu2-VirtualBox:~/week8/sliceable-switch-team-w$ ./bin/rackup
```

もう1つ別の端末で下記のコマンドを実行することで、2つのスライスa,bを作成した。
また、それぞれのスライスにMACアドレス11:11:11:11:11:11、22:22:22:22:22:22を持つホストを追加した。

```
ensyuu2@ensyuu2-VirtualBox:~/week8/sliceable-switch-team-w$ curl -sS -X POST -d '{"name": "a"}' 'http://localhost:9292/slices' -H Content-Type:application/json -v
* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9292 (#0)
> POST /slices HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost:9292
> Accept: */*
> Content-Type:application/json
> Content-Length: 13
> 
* upload completely sent off: 13 out of 13 bytes
< HTTP/1.1 201 Created 
< Content-Type: application/json
< Content-Length: 25
* Server WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26) is not blacklisted
< Server: WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26)
< Date: Tue, 13 Dec 2016 11:07:15 GMT
< Connection: Keep-Alive
< 
* Connection #0 to host localhost left intact
{"name": "a", "host": []}
ensyuu2@ensyuu2-VirtualBox:~/week8/sliceable-switch-tea'{"name": "b"}' 'http://localhost:9292/slices' -H Content-Type:application/json -v
* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9292 (#0)
> POST /slices HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost:9292
> Accept: */*
> Content-Type:application/json
> Content-Length: 13
> 
* upload completely sent off: 13 out of 13 bytes
< HTTP/1.1 201 Created 
< Content-Type: application/json
< Content-Length: 25
* Server WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26) is not blacklisted
< Server: WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26)
< Date: Tue, 13 Dec 2016 11:09:20 GMT
< Connection: Keep-Alive
< 
* Connection #0 to host localhost left intact
{"name": "b", "host": []}
ensyuu2@ensyuu2-VirtualBox:~/week8/sliceable-switch-tea'{"name": "11:11:11:11:11:11"}' 'http://localhost:9292/slices/a/ports/0x1:1/mac_addresses' -H Content-Type:application/json -v
* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9292 (#0)
> POST /slices/a/ports/0x1:1/mac_addresses HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost:9292
> Accept: */*
> Content-Type:application/json
> Content-Length: 29
> 
* upload completely sent off: 29 out of 29 bytes
< HTTP/1.1 201 Created 
< Content-Type: application/json
< Content-Length: 31
* Server WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26) is not blacklisted
< Server: WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26)
< Date: Tue, 13 Dec 2016 11:10:13 GMT
< Connection: Keep-Alive
< 
* Connection #0 to host localhost left intact
[{"name": "11:11:11:11:11:11"}]
ensyuu2@ensyuu2-VirtualBox:~/week8/sliceable-swit'{"name": "22:22:22:22:22:22"}' 'http://localhost:9292/slices/b/ports/0x2:2/mac_addresses' -H Content-Type:application/json -v
* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9292 (#0)
> POST /slices/b/ports/0x2:2/mac_addresses HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost:9292
> Accept: */*
> Content-Type:application/json
> Content-Length: 29
> 
* upload completely sent off: 29 out of 29 bytes
< HTTP/1.1 201 Created 
< Content-Type: application/json
< Content-Length: 31
* Server WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26) is not blacklisted
< Server: WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26)
< Date: Tue, 13 Dec 2016 11:10:44 GMT
< Connection: Keep-Alive
< 
* Connection #0 to host localhost left intact
[{"name": "22:22:22:22:22:22"}]
```

ブラウザを用いてhttp://localhost:9292/slices/にアクセスした。
ページには、```[{"name": "a", "host": ["11:11:11:11:11:11"]},{"name": "b", "host": ["22:22:22:22:22:22"]}]```と表示されていた。
このことから正常に2つのスライスa,bが作成されていて、ホストの追加もされていることが分かる。

コマンド```curl -sS -X POST -d '{"new_slice":"[new_slice_name]", "a_slice":"[old_slice_name_A]", "b_slice":"[old_slice_name_B]"}' '[new_slice_address]' -H Content-Type:application/json -v ```を実行することで2つのスライスをマージすることができる。
コマンド```curl -sS -X POST -d '{"new_slice":"c", "a_slice":"a", "b_slice":"b"}' 'http://localhost:9292/slices/c' -H Content-Type:application/json -v```を実行して、2つのスライスa,bをマージして新しいスライスcを作成する。
端末上の実行結果は以下のようになった。

```
ensyuu2@ensyuu2-VirtualBox:~/week8/sliceable-swit'{"new_slice":"c", "a_slice":"a", "b_slice":"b"}' 'http://localhost:9292/slices/c' -H Content-Type:application/json -v
* Hostname was NOT found in DNS cache
*   Trying 127.0.0.1...
* Connected to localhost (127.0.0.1) port 9292 (#0)
> POST /slices/c HTTP/1.1
> User-Agent: curl/7.35.0
> Host: localhost:9292
> Accept: */*
> Content-Type:application/json
> Content-Length: 47
> 
* upload completely sent off: 47 out of 47 bytes
< HTTP/1.1 201 Created 
< Content-Type: application/json
< Content-Length: 67
* Server WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26) is not blacklisted
< Server: WEBrick/1.3.1 (Ruby/2.2.1/2015-02-26)
< Date: Tue, 13 Dec 2016 11:11:34 GMT
< Connection: Keep-Alive
< 
* Connection #0 to host localhost left intact
[{"name": "c", "host": ["11:11:11:11:11:11", "22:22:22:22:22:22"]}]
```

また、ブラウザを用いてhttp://localhost:9292/slicesにアクセスした。
ページには```[{"name": "c", "host": ["11:11:11:11:11:11", "22:22:22:22:22:22"]}]```と表示されており、2つのスライスa,bがマージされていることが分かる。

