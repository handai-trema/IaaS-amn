# IaaS-amn

## 概要

課題で要求された仕様を満たすMini IaaSを作成する。
Mini IaaSは、コマンド操作により、LinuxVMを準備し、サービス提供するものである。
簡単には、以下のような手順によってMini IaaSの動作を確認できるものである。

1. CLI で Mini IaaS にサーバを数台立てる
2. Web インタフェースで状態を表示
3. 作成したサーバ上でごく簡単なサービスを起動
Web サーバ + DB サーバなど
4. +αで工夫した点や独自機能をデモ

## 各マシンの設定方法
各マシンに割り振るIPアドレスはIPリストから該当するものを選択して利用する．

ただし，VirtualBoxなどの仮想化ソフトウェアを利用し，
VMをマシンとして利用する場合には，
ホストマシンのイーサネットケーブルに割り振るIPアドレスをIPリストのOtherから選択し，
さらに各VMのアダプタの設定についてはブリッジアダプタを選択しなければならない．

また，本説明では仮想化ソフトウェアとしてVirtualBoxを用いて説明する．

### ユーザ用端末，管理用端末
ブラウザとpingをインストールし，IPをそれぞれ固定で割り振る．

### コントローラ
コントローラはスイッチネットワーク（スイッチのポート）と接続するインターフェース（以下 if-S）と，スイッチのマネージメントポートに接続するインターフェース（以下 if-M）が必要である．
これらのインターフェースには異なるIPアドレスを設定しておく．

また，スイッチの設定時にコントローラのIPアドレスを指定する場合には，
if-Mに設定したIPアドレスを指定する．

また，本演習で用いた実スイッチのIPアドレスは192.168.1.1/24に設定する．
fre
事前にruby2.2.5, bundler, gitをインストールし，以下のコマンドを実行して必要なプログラム及びパッケージをインストールしておく．
```
cd ~
git clone -b dev-nishimura https://github.com/handai-trema/IaaS-amn
cd IaaS-amn/
bundle install --binstubs
```

１. スイッチ及びスイッチのマネージメントポートに接続し，インターフェースにIPアドレスを設定する

２. 以下のコマンドを実行する．ただし，<if-M>はif-Mのインターフェース名を表す．
```
sudo route add -host 192.168.1.1 <if-M>
```
３. Webサーバを起動する
```
cd ~/IaaS-amn/
bin/rackup -o 0.0.0.0 &
```
４. コントローラを起動する
```
cd ~/IaaS-amn/
bin/trema run ./lib/routing_switch.rb
```
５. 終了するときは，Ctrl + Cでコントローラプログラムを終了し，killコマンドなどでWebサーバを終了する．

### VMマネージャ
事前にruby2.2.5, bundler, gitをインストールしておく．  
また，以下のコマンドを実行して，必要なプログラム及びパッケージをインストールしておく．
```
cd ~
git clone -b VMRESTAPI https://github.com/handai-trema/IaaS-amn
cd IaaS-amn/
bundle install --binstubs
```
1. スイッチに接続し，インターフェースにIPアドレスを設定する
2. IaaS-amn/ディレクトリ上で，以下のコマンドを実行し，Webサーバを起動する
```
./bin/rackup -o 0.0.0.0
```

### VMサーバ
以下からVMの仮想イメージをダウンロードし，利用する．

ダウンロードURL  
[ vmmanager.ova ](https://ecsosaka-my.sharepoint.com/personal/u141594c_ecs_osaka-u_ac_jp/_layouts/15/guestaccess.aspx?docid=05b93cfed22144d0fb1715bd45ddf518f&authkey=AWI5hSepDEk9yE5A7zCg48I)

1. 仮想イメージをインポートし，仮想マシンを作成する
2. 仮想マシンのネットワーク設定からアダプタ1，2のネットワーク設定をブリッジアダプタにする．ホストマシンのアダプタにはスイッチネットワークと接続されているアダプタを選択する．  
アダプタ2は高度な設定を開いて，プロミスキャスモードを「すべて許可」にしておく．
3. 仮想マシンを起動し，ログインする
```
login: vmmanager  
password: password
```
4. ifconfig でeth0, eth1, docker0, docker1ができていることを確認する．  
また，各インターフェースのIPアドレスがeth0: 192.168.1.4, eth1: 192.168.1.5, docker1: 192.168.1.5となっていることを確認する
5. 以下のようにしてeth1のIPアドレスを消去する
```
sudo ip addr del 192.168.1.5/24 dev eth1
```
6. 以下のコマンドによってコンテナと外部ネットワークをつなぐブリッジと仮想マシンのインターフェースを接続する
```
sudo brctl addif docker1 eth1
```
7. 以下のコマンドによってREST APIによる命令を処理するためのWebサーバを起動する
```
cd ~/iaas-amn
./bin/rackup -o 0.0.0.0
```

### コンテナ
コンテナの持つIP向けに同じネットワークからSSHすると，コンテナを利用できる．

ユーザ名及びパスワードは以下である．

ID: root  
Pass: root

ID: admin  
Pass: password

ID: enduser  
Pass: password

## 利用手順
1. スイッチを起動する
2. コントローラをスイッチに接続し，起動する
3. 管理用端末をスイッチに接続し，起動する
4. 管理用端末からコントローラの<if-S>にpingコマンドを実行し，通信できることを確認する
5. 管理用端末のブラウザから<if-S>にアクセスし，トポロジ情報にアクセスできることを確認する
6. VMマネージャを起動し，<if-S>にpingコマンドを実行し，通信できることを確認する
7. VMサーバを起動し，<if-S>にpingコマンドを実行し，通信できることを確認する
8. ユーザ端末を起動し，VMマネージャにpingコマンドを実行し，通信できることを確認する
9. ユーザ端末のブラウザからVMマネージャのIPアドレスを利用してWebインターフェースにアクセスし，コンテナ要求を行う
10. ユーザ端末からコンテナのIPアドレスにSSHコマンドを実行し，コンテナの操作を行う

## IPリスト

| 機器         |                    IP アドレス (ネットマスク長24)|
|:-------------|-------------------------------:|
| スイッチ     |                    192.168.1.1 |
| VMサーバ |     192.168.1.2 〜 192.168.1.5 |
| VMマネージャ |      192.168.1.6 |
| 管理用端末   |     192.168.1.7 〜 192.168.1.9 |
| コンテナ           |  192.168.1.10 〜 192.168.1.199 |
| ユーザ端末   | 192.168.1.200 〜 192.168.1.232 |
| other        | 192.168.1.233 〜 192.168.1.247 |
| コントローラ |       192.168.1.251 〜 192.168.1.254 |
