# レポート等に関するメモ

## 1. 要件

### 1.1 最終レポートについて

以下の通りに最終課題をまとめてPPTXファイルを提出してください。

締切：2/8  
提出物：PPTXファイル（グループで1つ）  
送付先：ein2-ta16@ane.cmc.osaka-u.ac.jp  
PPTXの内容：
- 班員の情報（学籍番号・メールアドレスなども）
- デモ内容の説明（今日のスライドをベースにしてもOK）
 - デモの内容が当初予定していたものと異なる場合は以下も明記
   - 差が出た要因
   - 予定通りに進まなかった要因
 - OpenFlowが、どこに、どのように使われているかが明記されていない場合はそれも明記
- 今日のデモの質疑まとめ
- 取り組みのスケジュール（事前の計画と実際の進捗）
- 役割分担
- 成果物の公開場所

### 1.2 成果物の公開について

成果物一式をGithubで公開してください。

締切：2/8  
公開の条件・方法：  
- 公開したURLは上記の最終レポートのPPTXファイルに明記すること
- 成果物一式の使い方を README.md で説明する。この説明を見ながら今日のデモが再現できる程度に記述すること。
- 各マシンの設定方法も記述すること。もしくは、設定済みのVMイメージをアップロードし、その利用方法のまとめでも良い。
- VMなどファイルサイズが大きい場合はDropboxや研究室のWebサーバーなどにアップロードしても良い。
 - Dropboxや研究室のWebサーバーなどにアップし、そのアクセス情報をGithubで公開できない場合は、最終レポートにのみURLを記載しても良い。

## 2. 内容

### 2.1 最終レポート

#### 2.1.1 構成

##### 1. 班員情報
  * 班員の名前，学籍番号，メールアドレスのテーブル（学籍番号順にソート）

##### 2. デモ内容の説明
1. IaaS
      1. ネットワークモデル（もうちょっと制御とデータの話をわけたほうがよいね．上位層でCプレーンとUプレーン別に図を描いたほうがよいかも．OpenFlowを強調するためにも．）
        * トポロジ（既存のやつ）
        * Cプレーン（追加）
        * Dプレーン（追加）
      2. IaaSの機能
        * ユーザはVMマネージャ上のWebページにアクセスし，GUI操作によって任意の台数のコンテナを要求可能（OpenFlowによるパケットのL2, L3配送）
        * VMマネージャは，コンテナ割り当て用のIPアドレスプールを管理し，VMサーバに対して指定したIPで新たなコンテナの作成を要求する
        * ユーザは割り当てられたコンテナを，sshで自由に操作可能（OpenFlowによるパケットのL2, L3配送）
        * ユーザとコンテナ間にはプライベートネットワークが形成され，他のユーザからのアクセスを防ぐことが可能（OpenFlowによるスライスの実現）
        * コントローラとネットワーク管理用端末は独自の管理用ネットワークを持ち，ユーザからのアクセスを受けない（OpenFlowによるスライスの実現）
      3. デモ
        * コントローラを起動
        * 管理用端末を起動し，コントローラ上のWebインターフェースにアクセスし，トポロジを確認
        * コンテナ要求用のWebサーバ（VMマネージャ）を起動
        * ユーザ端末1からVMマネージャ上のWebサーバにアクセスし，Webインターフェースからコンテナの利用開始を要求（複数台のコンテナを要求）
        * 管理用端末のWebインターフェースにより，コンテナの起動を確認
        * ユーザ端末1からコンテナとの接続を（pingコマンド）確認し，sshコマンドを利用してコンテナが操作可能なことを確認
        * ユーザ端末2をスイッチネットワークに接続し，ユーザ端末1及びユーザ端末1に割り当てられたコンテナと通信できないことをpingコマンドにより確認
      4. 各端末，ノードの説明
        * スイッチ：ネットワークを構成
        * コントローラ（制御プレーン）
            * インターフェース：
              * スイッチをマネージメントするインターフェース
              * トポロジ情報を管理用端末に返すための制御プレーンインターフェース
            * 機能：
              * OpenFlowを用いたスイッチの管理，制御
              * Webサーバ（管理用端末によるトポロジ情報の確認用）
            * スライス：
              * NW管理スライス，VM管理スライス
        * 管理用端末
            * インターフェース：
              * トポロジ情報をコントローラに要求するための制御プレーンインターフェース
            * 機能：
              * ブラウザによってコントローラ上のWebインターフェースにアクセスし，トポロジを確認
            * スライス：
              * NW管理スライス
        * ユーザ端末
            * インターフェース：
              * コンテナ要求およびコンテナの利用をするためのインターフェース
            * 機能：
              * ブラウザによってVMマネージャ上のWebインターフェースにアクセスし，コンテナの利用を要求
              * SSHコマンドにより割り当てられたコンテナを操作
            * スライス：
              * プライベートスライス（ユーザごとに存在）
        * VMマネージャ
            * インターフェース：
              * コンテナ要求用の制御プレーンインターフェース
            * 機能：
              * Webサーバ（ユーザ端末によるコンテナ要求用）
              * コンテナに割り当てるIPアドレスの管理
              * VMサーバにコンテナを要求
              * コントローラにプライベートスライスの追加を要求
            * スライス：
              * プライベートスライス（ユーザごとに存在）
              * VM管理スライス
        * VMサーバ
            * インターフェース：
              * コンテナ要求用の制御プレーンインターフェース
              * コンテナ通信用のデータプレーンインターフェース
            * 機能：
              * Webサーバ（VMマネージャによるコンテナ要求用）
              * コンテナの作成，起動
            * スライス：
              * プライベートスライス（ユーザごとに存在）
              * VM管理スライス
        * コンテナ
            * インターフェース：
              * コンテナ通信用のデータプレーンインターフェース
            * 機能：
              * SSHやWebサーバ機能など
            * スライス：
              * プレイべーとスライス
      5. 実際の画面（3に組み込んだほうがよいかもしれない）
2. 故障スイッチの回避
      1. 背景，目的
        * 背景（適当に書いてるから文章はなおす）
            * スイッチやLANケーブルは劣化する
            * 劣化によりパフォーマンスが落ちる
            * パフォーマンスが落ちたスイッチを発見し，迂回できればネットワークに与える悪影響（具体的な用語に直す）を小さくできる
            * さらに，そのスイッチをフリーにできるのでスイッチを直したり新しいものにとりかえることが容易にできる
        * 目的
            * パフォーマンスの低下したスイッチを検出し，パス計算時に除外することでネットワーク全体に与える悪影響（具体的に）を低減する
      2. 手法
        1. コントローラが定期的に，各スイッチに関する以下の統計情報と時刻$t_i$を記録する
            * 受信パケット数: $ Rx_i $
            * 転送パケット数: $ Tx_i $
            * ドロップパケット数: $ Dx_i $
        2. スイッチごとに以下の指標を計算する
            * $ r_i = \frac{(Tx_i - Tx_{i-1}) + (Dx_i - Dx_{i-1})}{Rx_i - Rx_{i-1}} $
            * $ p_i = \frac{Tx_i - Tx_{i-1}}{} $
        3. 以下の表に基づき故障かどうかを判定
            * 表を乗っける
            * 閾値の説明をする（r_i > r_th は何を意味しているのか具体的に）
        4. パス計算時に，判定されたスイッチを除外して計算を行う
      3. 動作確認，デモ
        1. パフォーマンスの低下を実現
            1. 仮想マシンでリピータを作成し，スイッチ間に接続
            2. 仮想マシン上でネットワークインターフェースに対し，tcコマンドを用いて遅延を発生させる
            3. スイッチは，リピータに接続されているリンクに対してパケットの転送速度を下げることになり，パフォーマンスの低下が実現できる
        2. OpenFlow 1.0で定められているPort…を取得できなかったため，追加機能のデモができなかった
            * TremaにはPortStatsRequestは用意されているが，PortStatsReplyクラスは存在せず，StatsReplyクラスでもPortStatsReplyを処理できない
            * PortStatsReplyの実装を試みたが，時間が足りなかった

##### 3. 質疑まとめ
###### ドロップパケット数
【質問】
追加機能の性能指標を計算する際に，スイッチの「受信パケット数」と「転送パケット数」の比を計算しているが，（異なるスライス間の端末を宛先としたパケットのように）ドロップしたパケット数は含めなくてよいのか

【回答/考察】
含めなくてはならない（考察不足だったが，PortStatsReplyの未実装問題でテストができなかったため気づけなかった）．

###### インターフェース及びリンクのパフォーマンス低下
【質問】
スイッチのインターフェースやリンクのパフォーマンスが低下することも考えられるが，なぜ今回はスイッチ本体のパフォーマンス低下の検知にしたのか

【回答/考察】
PortStatsReplyにより，スイッチに存在するポートごとに受信・転送・ドロップパケット数を得ることができ，また，パスごとに性能を計算することによってスイッチの持つインターフェースやリンクのパフォーマンス低下を検知することができる．さらに，同一のリンクに関して双方向の性能計算を行うことでパフォーマンスの低下がインターフェースのものかリンクのものかも判定することができる．

しかしながら，実現可能性については議論し，考察したものの，今回は実装のためにかかる工数および時間の観点からスイッチのパフォーマンス低下を検知するにとどまった．

###### 努力した点
【質問】
頑張った点をアピールしてください

【回答/考察】
* 作業前に話し合い，仕様書（ガイドライン）を作成・編集することで，分担して作業をする際にも，班員の作業内容や各種仕様（構成や利用するIPアドレス・Rest APIのためのURIにいたるまで）を確認することができた
* 分担作業時の個別テスト，組み合わせたときの統合テストを事前に考えてから実行することで，「テスト漏れ」がないようにした
* 「自然なIaaSを目指す」というのをコンセプトに掲げており，不自然な仕様の排除に努めた
  * VMマネージャとVMサーバを分離することにより，VMマネージャおよびVMサーバを管理しているサービス事業者は，必要に応じて簡単にVMサーバを増やすことができる（設備投資や事業拡大が簡単になる）
  * ユーザ端末や管理用端末は複数存在しうる
  * 「管理用端末以外の端末は，コントローラのIPも知らず，仮に知っていても一切アクセスできない」というような自然なアクセス規則
* 「OpenFlowで実現する」という利点を利用するため，スライスやインターフェースの工夫によるプレーン分離を実現した

###### 大変だった点
【質問】
大変だったところを教えてください

【回答/考察】
* Dockerを利用した固定IPでのコンテナ作成及びVMサーバ外の端末とコンテナとの通信実現
* 仮想環境で動く状態のものを実スイッチを通して動くようにするための調整および正常に動作できない原因究明
* 追加機能におけるPortStatsReplyの実装（できなかった）

##### 4. 取り組みのスケジュール（表？）
【予定】
* 12/21 ガイドラインのプロトタイプ完成
* 1/11 ガイドラインの詳細化，dockerによるコンテナ作成およびコンテナのネットワーク参加実現，L3配送の実現
* 1/18 スライス機能の実装，トポロジ情報の可視化完成，追加機能の実装アルゴリズム考案
* 1/25 IaaS完成，追加機能の実装開始
* 2/1 追加機能実装完了

【実際】
* 12/21 ガイドラインのプロトタイプ完成
* 1/11 ガイドラインの詳細化
* 1/18 IPリスト作成
* 1/24 VMマネージャ上のREST API実装，トポロジの可視化機能完成，dockerによるコンテナ作成およびコンテナのネットワーク参加実現
* 1/25 L3配送の実現，発表資料作成開始
* 1/26 追加機能の実装アルゴリズム考案，パフォーマンス低下実現用リピータの作成
* 1/28 複数のVMサーバに対応できるよう，VMマネージャとVMサーバの分離
* 1/31 IaaS完成，追加機能の実装（未完成）

##### 5. 役割分担（表で）
* 阿部 ガイドライン執筆，docker，スライド，テスト
* 佐竹 トポロジの可視化，ガイドライン執筆，IPリスト，テスト
* 錦織 docker，スライド・発表，テスト
* 西村 REST API(コントローラ，VMマネージャ，VMサーバなど)，コントローラ実装，テスト

##### 6. 成果物の公開場所



### 2.2 成果物の公開
各端末，ノードごとに用意する．

* コントローラ：端末に必要なパッケージ（Apache，ruby2.5）を記述，クローンしてくるブランチをコマンドとともにReadme.mdに記述．そのうえで，仮想アプライアンスを公開し，VirtualBoxの設定もReadme.mdに記述．
* 管理用端末：pingの送信後，ブラウザによってコントローラ上のWebインターフェースにアクセスできれば良い，とReadme.mdに記述．
* ユーザ端末：pingの送信後，ブラウザによってVMマネージャ上のWebインターフェースにアクセスできれば良い，sshが必要
* VMマネージャ：REST API用のWebサーバ機能が必要，クローンしてくるブランチをコマンドとともにReadme.mdに記述．仮想アプライアンスを公開し，VirtualBoxの設定も記述．
* VMサーバ：REST API用のWebサーバ機能が必要，クローンしてくるブランチをコマンドとともにReadme.mdに記述．DockerCloneするDockerHub上のイメージを記述．さらに，仮想アプライアンス公開，VBの設定を記述．