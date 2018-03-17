#===================================================================
#        データベースへのアップロード
#-------------------------------------------------------------------
#            (C) 2013 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/lib/IO.pm";

# パッケージの定義    ---------------#    
package Upload;
use strict;
use warnings;

# パッケージの使用宣言    ---------------#
use Encode;
use Encode 'from_to';

require LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;
use DBI;
use DBIx::Custom;

use source::DbSetting;       #データベース設定呼び出し
use ConstData_Upload;        #定数呼び出し

#-----------------------------------#
#        コンストラクタ
#-----------------------------------#
sub new {
    my $class  = shift;
    my $dbi    = "";
    my $user   = DbSetting::USER;
    my $pass   = DbSetting::PASS;
    my $dsn    = DbSetting::DSN;
  
    bless {
        DBI   => $dbi,
        User  => $user,
        Pass  => $pass,
        Dsn   => $dsn,
    }, $class;
}

# 宣言部    ---------------------------#

sub Upload {
    my $self       = shift;
    my $fileName   = shift;
    my $for_table  = shift;
    
    print "Uproad to \"$for_table\"...\n";
    #読み込んだファイル内容の展開
    if(&IO::Check($fileName)){
        
        $self->{FileData} = &IO::FileRead ($fileName);
        my @fileData    = split(/\n/, $self->{FileData});
        
        my $data_head    = shift(@fileData);
        $data_head =~ s/\r\n/\n/g;
        $data_head =~ s/\r/\n/g;
        chomp($data_head);
        my @data_head    = split(ConstData::SPLIT , $data_head );#先頭情報の除去
        
        my @dataQue        = ();
        
        foreach my $lineData(@fileData){
        
            #行ごとのデータを展開
            my @oneFileData = split(ConstData::SPLIT, $lineData);
            
            
            #データ追加
            if (scalar(@oneFileData)){
                &AddArray($self, \@dataQue, \@oneFileData, \@data_head, $for_table);
            }
            #データ100件ごとにデータ送信
            if(scalar(@dataQue) > 100){
                &InsertDB($self,\@dataQue,$for_table);
                print $oneFileData[2] . "\n";
                @dataQue =();
            }            
        }
        &InsertDB($self,\@dataQue,$for_table);
    }
    

    return;
}

sub AddArray {
    my $self       = shift;
    my $dataQue    = shift;
    my $addData    = shift;
    my $data_head  = shift;
    
    my $queData = {};
    
    my $max_data_size = scalar(@$data_head);
    
    foreach    (my $i="0";$i < $max_data_size;$i++){
        $$queData{$$data_head[$i]} = $$addData[$i];
    }
    push (@$dataQue, $queData);
    return;
}

sub GetMinimum{
    my $self   = shift;
    my $num_a  = shift;
    my $num_b  = shift;
    
    if($num_a < $num_b){
        return $num_a;
    }else{
        return $num_b;
    }

}


#-----------------------------------#
#
#        データの挿入
#
#-----------------------------------#
sub InsertDB{
    my $self        = shift;
    my $insertData  = shift;
    my $tableName   = shift;
    
    eval {
        $self->{DBI}->insert($insertData, table     => $tableName);
    };
    if ( $@ ){
        if ( DBI::errstr &&  DBI::errstr =~ "for key 'PRIMARY'" ){
            my $errMes = "[一意制約]\n";
            from_to($errMes, 'UTF8', 'cp932');
            print $errMes;
        } else {
            my $errMes = "$@";
            from_to($errMes, 'UTF8', 'cp932');
            die $errMes;
        }
    }
    
    return;
}



#-----------------------------------#
#
#        テーブルデータの全削除
#
#-----------------------------------#
sub DeleteAll{
    my $self        = shift;
    my $tableName   = shift;
    
    $self->{DBI}->delete_all( table => $tableName );
    return;
}

#-----------------------------------#
#
#    同じ日付のデータを削除する
#
#-----------------------------------#
sub DeleteSameDate{
    my $self       = shift;
    my $tableName  = shift;
    my $date       = shift;

    print  $date . "\n";
    
    $self->{DBI}->delete(
        table => $tableName,
        where => {created_at => $date,}
        );
    return;
}
#-----------------------------------#
##
##       同じ更新回のデータを削除する
##
##-----------------------------------#
sub DeleteSameResult{
    my $self        = shift;
    my $tableName   = shift;
    my $result_no   = shift;
    my $generate_no = shift;
    
    $self->{DBI}->delete(
            table => $tableName,
            where => {result_no   => $result_no,}
                      #generate_no => $generate_no,}
        );
    return;
}

#-----------------------------------#
#
#        データベース接続
#
#-----------------------------------#
sub DBConnect {
    my $self        = shift;
    
  
    # Connect
    $self->{DBI} = DBIx::Custom->connect(
        dsn         => $self->{Dsn},
        user        => $self->{User},
        password    => $self->{Pass},
        option      => {mysql_enable_utf8 => 1},
    ) or die "cannot connect to MySQL: $self->{DBI}::errstr";
    
    return;
}
1;
