#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

RESULT_NO=`printf "%d" $1`
GENERATE_NO=$2

ZIP_NAME=${RESULT_NO}_$GENERATE_NO

if [ -z "$RESULT_NO" ]; then
    exit
fi

if [ ! -f ./data/orig/turn${ZIP_NAME}.zip ]; then
    wget -O data/orig/turn${ZIP_NAME}.zip http://csyuki.sakura.ne.jp/cgi-bin/prism/result/turn${RESULT_NO}.zip
fi

# 元ファイルを変換し圧縮
if [ -f ./data/orig/turn${ZIP_NAME}.zip ]; then
    
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

fi

perl ./GetData.pl $1 $2
perl ./UploadParent.pl $1 $2

# UTFファイルを圧縮
if [ -d ./data/utf/turn${ZIP_NAME} ]; then
    
    cd ./data/utf/

    echo "utf zip..."
	zip -qr ./turn${ZIP_NAME}.zip ./turn${ZIP_NAME}
    echo "rm utf..."
    rm  -r turn${ZIP_NAME}
        
    cd ../../

fi

cd $CURENT  #元のディレクトリに戻る
