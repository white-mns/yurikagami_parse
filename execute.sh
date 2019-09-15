#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

#------------------------------------------------------------------
# 更新回数、再更新番号の定義確認、設定

RESULT_NO=`printf "%d" $1`
GENERATE_NO=$2

if [ -z "$RESULT_NO" ]; then
    exit
fi

# 再更新番号の指定がない場合、取得済みで最も再更新番号の大きいファイルを探索して実行する
if [ -z "$2" ]; then
    for ((GENERATE_NO=5;GENERATE_NO >=0;GENERATE_NO--)) {
        
        ZIP_NAME=${RESULT_NO}_$GENERATE_NO

        echo "test $ZIP_NAME"
        if [ -f ./data/orig/turn${ZIP_NAME}.zip ]; then
            echo "execute $ZIP_NAME"
            break
        fi
    }
fi

if [ $GENERATE_NO -lt 0 ]; then
    exit
fi

ZIP_NAME=${RESULT_NO}_$GENERATE_NO

#------------------------------------------------------------------
# 圧縮結果をダウンロード。
if [ ! -f ./data/orig/turn${ZIP_NAME}.zip ]; then
    wget -O data/orig/turn${ZIP_NAME}.zip http://csyuki.sakura.ne.jp/cgi-bin/prism/result/turn${RESULT_NO}.zip
fi

# 圧縮結果ファイルを展開
if [ -f ./data/orig/turn${ZIP_NAME}.zip ]; then

    echo "open archive..."
    
    cd ./data/orig

    echo "unzip orig..."
    mkdir turn${ZIP_NAME}
    unzip -oq ./turn${ZIP_NAME}.zip -d turn${ZIP_NAME}

    cp -r  turn${ZIP_NAME} ../utf/turn${ZIP_NAME}
    echo "rm orig..."
    rm  -rf turn${ZIP_NAME}

    echo "shift-jis to utf8..."
    cd ../utf/turn${ZIP_NAME}/
    nkf -w --overwrite *.html
    nkf -w --overwrite *.css
    
    cd ../../../

    perl ./GetData.pl      $RESULT_NO $GENERATE_NO
    perl ./UploadParent.pl $RESULT_NO $GENERATE_NO

#------------------------------------------------------------------
# 展開したファイルを削除
    
    cd ./data/utf/

    echo "utf zip..."
	zip -qr ./turn${ZIP_NAME}.zip ./turn${ZIP_NAME}

    echo "rm utf..."
    rm  -r turn${ZIP_NAME}
    
    cd ../../
 
fi

./data/www/_re_expansion.sh $RESULT_NO

cd $CURENT  #元のディレクトリに戻る
