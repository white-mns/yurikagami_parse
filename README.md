# 百合鏡4期データ小屋　解析プログラム
百合鏡4期データ小屋は[百合鏡](http://csyuki.sakura.ne.jp/cgi-bin/prism/)を解析して得られるデータを扱った情報サイトです。  
このプログラムは四城半データ小屋で実際に使用している解析・DB登録プログラムです。  
データ小屋の表示部分については[別リポジトリ](https://github.com/white-mns/yurikagami_rails)を参照ください。

# サイト
実際に動いているサイトです。  
[百合鏡データ小屋](http://tkg.mn-s.net/yk_4)

# 動作環境
以下の環境での動作を確認しています  
  
OS:CentOS release 6.5 (Final)  
DB:MySQL  
Perl:5.10.1  

## 必要なもの

bashが使えるLinux環境。（Windowsでやる場合、execute.shの処理を手動で行ってください）  
perlが使える環境  
デフォルトで入ってないモジュールを使ってるので、

    cpan DateTime

みたいにCPAN等を使ってDateTimeやHTML::TreeBuilderといった足りないモジュールをインストールしてください。

## 使い方

第一回更新、再更新なしなら

    ./execute.sh 1 0

とします。
最更新が1回あって圧縮ファイルが`002_1.zip`となっている場合、その数字に合わせて

    ./execute.sh 2 1

とします。
上手く動けば、まず圧縮ファイルがダウンロードされdata/origに置かれます。  
次にファイルを展開してdata/utfにコピーし、UTF-8に文字コードを変換します。
（実際に稼働してる環境ではdataディレクトリはシンボリックリンクにしていて、`/var/tkg/yk_4/utf`に圧縮ファイルを置いています。複数の定期ゲを解析する際、圧縮ファイルの場所はまとめておきたいので)
その後解析が行われ、output内に中間ファイルcsvが生成されて指定したDBにデータが登録されます。
どの項目について実行するかは`ConstData.pm`及び`ConstData_Upload.pm`で制御します

## DB設定
`source/DbSetting.pm`にサーバーの設定を記述します。  
DBのテーブルは[Railsアプリ側](https://github.com/white-mns/yurikagami_rails)で`rake db:migrate`して作成しています。

## 中間ファイル
DBにアップロードしない場合、固有名詞を数字で置き換えている箇所があるため、csvファイルを読むのは難しいと思います。

    $self->{CommonDatas}{ProperName}->GetOrAddId($$data[2])

のような`GetOrAddId`、`GetId`関数で変換していますので、似たような箇所を全て

    $$data[2]

のように中身だけに書き換えることで元の文字列がcsvファイルに書き出され読みやすくなります。

## ライセンス
本ソフトウェアはMIT Licenceを採用しています。 ライセンスの詳細については`LICENSE`ファイルを参照してください。
