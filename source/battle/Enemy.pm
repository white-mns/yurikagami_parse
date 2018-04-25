#===================================================================
#        敵情報一覧取得パッケージ
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
package Enemy;

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
    $self->{Datas}{EnemyPartyInfo} = StoreData->new();
    $self->{Datas}{Enemy}          = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "enemy_num",
    ];
    $self->{Datas}{EnemyPartyInfo}->Init($header_list);
    
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "enemy",
                "suffix",
    ];
    $self->{Datas}{Enemy}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{EnemyPartyInfo}->SetOutputName( "./output/battle/enemy_party_info_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{Enemy}         ->SetOutputName( "./output/battle/enemy_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $bstat_table_nodes = shift;
    
    $self->{PartyNo} = $party_no;
    $self->{Enemy}  = {};

    $self->GetEnemyData($bstat_table_nodes);
    
    return;
}
#-----------------------------------#
#    パーティ所属データ取得
#------------------------------------
#    引数｜キャラ情報データノード
#-----------------------------------#
sub GetEnemyData{
    my $self  = shift;
    my $bstat_table_nodes = shift;

    my $enemy_num = 0;

    foreach my $bstat_table_node (@$bstat_table_nodes) {
        my $vspt_tr_nodes  = &GetNode::GetNode_Tag_Class("tr","vspt", \$bstat_table_node);
        foreach my $vspt_tr_node (@$vspt_tr_nodes){
            my $td_nodes = &GetNode::GetNode_Tag("td", \$vspt_tr_node);

            my $enemy_full_name = $$td_nodes[0]->as_text; 
            my $enemy_name = $enemy_full_name;
            my $suffix     = "";
            if($enemy_full_name =~ /(.+?) (.{1,3}$)/){
                $enemy_name = $1;
                $suffix = $2;
            }
            my $enemy_id = $self->{CommonDatas}{EnemyName}->GetOrAddId($enemy_name);

            if(!exists($self->{Enemy}{$enemy_full_name})){ 
                $enemy_num += 1;

                my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $enemy_id, $suffix);
                $self->{Datas}{Enemy}->AddData(join(ConstData::SPLIT, @datas));
            }

            $self->{Enemy}{$enemy_full_name} = $enemy_full_name;
        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $enemy_num);
    $self->{Datas}{EnemyPartyInfo}->AddData(join(ConstData::SPLIT, @datas));

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
