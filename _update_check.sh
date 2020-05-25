#!/bin/bash

CURENT=`pwd`	#実行ディレクトリの保存
cd `dirname $0`	#解析コードのあるディレクトリで作業をする

RESULT_NO=$1
GENERATE_NO=$2

while :
do
    wget http://csyuki.sakura.ne.jp/cgi-bin/prism/
    nkf -w --overwrite index.html

    grep "現在更新作業中です。" index.html  >/dev/null 2>&1

    IS_UPDATE=$?
    rm index.html
    echo $IS_UPDATE

    if [ $IS_UPDATE -eq 1 ]; then
        echo "update!!"
        ./execute.sh ${RESULT_NO} ${GENERATE_NO}
        exit
    fi

    echo "no..."

    sleep 1800
done
