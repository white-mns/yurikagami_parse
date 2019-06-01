#===================================================================
#        パーティ情報一覧取得パッケージ
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
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
package PartyInfo;

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
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "name",
                "member_num",
                "battler_num",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/party_info_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜パーティ番号,パーティ名ノード,戦闘状況テーブル
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $party_no  = shift;
    my $h1_node          = shift;
    my $bstat_table_node = shift;
    
    
    $self->{PartyNo} = $party_no;

    $self->GetPartyNameData($h1_node);
    $self->GetPartyNumData($bstat_table_node);
    
    return;
}

#-----------------------------------#
#    パーティ名データ取得
#------------------------------------
#    引数｜パーティ名ノード
#-----------------------------------#
sub GetPartyNameData{
    my $self  = shift;
    my $h1_node = shift;

    $self->{PartyName} = $h1_node ? $h1_node->as_text : "";

    return;
}

#-----------------------------------#
#    パーティ人数データ取得
#------------------------------------
#    引数｜戦闘状況テーブル
#-----------------------------------#
sub GetPartyNumData{
    my $self  = shift;
    my $bstat_table_node = shift;

    my $battler_num = 0;
    my $sook_num = 0;
    foreach my $e_no (keys(%{$self->{CommonDatas}{Party}{$self->{PartyNo}}})) { # 所属するEno一覧を取得
        foreach my $nickname (keys(%{$self->{CommonDatas}{Battler}{$e_no}})){
            # Enoを元に、サブキャラ全員の通り名とボスフラグ込での判定人数を取得、それをこの戦闘に参加する通り名に関連付けて展開する
            $self->{Battler}{$nickname} = $self->{CommonDatas}{Battler}{$e_no}{$nickname};
        }
    }

    if ($bstat_table_node) {
        my $plpt_tr_nodes  = &GetNode::GetNode_Tag_Attr("tr", "class", "plpt", \$bstat_table_node);
        foreach my $plpt_tr_node (@$plpt_tr_nodes){
            my $td_nodes = &GetNode::GetNode_Tag("td", \$plpt_tr_node);
            my $nickname = $$td_nodes[0]->as_text; 

            if(!exists($self->{Battler}{$nickname})){ next;}
            $battler_num += $self->{Battler}{$nickname}; # ボスフラグ込での判定人数取得
        }
    }

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $self->{PartyName}, scalar(keys(%{$self->{CommonDatas}{Party}{$self->{PartyNo}}})), $battler_num) ));
    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
