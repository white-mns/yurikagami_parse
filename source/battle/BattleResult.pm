#===================================================================
#        戦闘結果一覧取得パッケージ
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
package BattleResult;

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
				"battle_result",
                "is_pk",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/battle_result_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $finish_div_node = shift;
    my $battle_div_node = shift;
    my $quest_div_node  = shift;
    
    $self->{PartyNo} = $party_no;
    $self->{IsPK} = $self->isPractice($quest_div_node);

    $self->GetBattleResultData($finish_div_node, $battle_div_node);
    
    return;
}

#-----------------------------------#
#    対人戦かどうかの判定
#------------------------------------
#    引数｜クエスト情報ノード
#-----------------------------------#
sub isPractice{
    my $self      = shift;
    my $quest_div_node    = shift;
    
    if (!$quest_div_node) { return 1;} # クエスト情報ノードがない場合、とりあえず敵の取得処理を実行する（ただし戦闘自体がないものと予想される）
    my $text = $quest_div_node->as_text;
    
    if ($text =~ /練習試合を申し込んだ。.+?はそれに応じた。/) { return 1;}
    if ($text =~ /PKを開始します。/) { return 2;}

    return 0;
}


#-----------------------------------#
#    戦闘結果データ取得
#------------------------------------
#    引数｜パーティ名ノード,戦闘状況テーブル
#-----------------------------------#
sub GetBattleResultData{
    my $self  = shift;
    my $finish_div_node = shift;
    my $battle_div_node = shift;

    my $battle_result = 0;
    if ($finish_div_node) {
        $battle_result = ($finish_div_node->as_text =~ /勝利した！/) ? 1  : $battle_result;
        $battle_result = ($finish_div_node->as_text =~ /敗北した…/) ? -1 : $battle_result;
    } else {
        $battle_result = -2;
    }

    if ($battle_div_node && $battle_div_node =~ /HASH/) {
        my $b_nodes = &GetNode::GetNode_Tag("b", \$battle_div_node);
        foreach my $b_node (reverse @$b_nodes) {
            if ($b_node->as_text =~ /勝利した！/){
                $battle_result = 1;
                last;
            }
            if ($b_node->as_text =~ /敗北した…/) {
                $battle_result = -1;
                last;
            }
            if ($b_node->as_text =~ /これ以上戦えないため、休戦した。/) {
                $battle_result = 0;
                last;
            }
        }
    }

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $battle_result, $self->{IsPK}) ));

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
