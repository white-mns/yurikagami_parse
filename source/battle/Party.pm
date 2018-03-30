#===================================================================
#        パーティ所属一覧取得パッケージ
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#   
use strict;
use warnings;
require "./source/lib/Store_Data.pm";
require "./source/lib/Store_HashData.pm";
use ConstData;        #定数呼び出し
use source::lib::GetNode;


#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#     
package Party;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  
  bless {
        Datas => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init(){
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "e_no",
                "sub_no",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/party_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜パーティ番号,キャラ情報データノード
#-----------------------------------#
sub GetData{
    my $self      = shift;
    my $party_no  = shift;
    my $stat_table_nodes = shift;
    
    $self->{PartyNo} = $party_no;

    $self->GetPartyData($stat_table_nodes);
    
    return;
}
#-----------------------------------#
#    パーティ所属データ取得
#------------------------------------
#    引数｜キャラ情報データノード
#-----------------------------------#
sub GetPartyData{
    my $self  = shift;
    my $stat_table_nodes = shift;

    foreach my $stat_table_node (@$stat_table_nodes){
        my $sttitle_nodes  = &GetNode::GetNode_Tag_Class("td","sttitle", \$stat_table_node);
        my @children = $$sttitle_nodes[0]->content_list();
   
        my $e_no_text = $children[1];
        $e_no_text =~ /\(ENo.(\d+)\)/;
        my $e_no = $1;

        # 結果上部と下部にそれぞれキャラクターの情報があるため、Enoがキーのハッシュ変数にしてダブった情報をまとめる。
        # また、その情報は他のデータ取得時に参照するため共通変数に渡す
        $self->{CommonDatas}{Party}{$self->{PartyNo}}{$e_no} = 1;
    }

    foreach my $e_no (sort{$a <=> $b} keys(%{$self->{CommonDatas}{Party}{$self->{PartyNo}}})){
        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $e_no, 0);
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));
    }

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output(){
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
