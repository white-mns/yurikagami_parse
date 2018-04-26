#===================================================================
#        ドロップ一覧取得パッケージ
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
package ItemGet;

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
                "enemy",
                "item",
                "is_pk",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/item_get_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜パーティ番号,パーティ名ノード,戦闘状況テーブル
#-----------------------------------#
sub GetData{
    my $self      = shift;
    my $party_no  = shift;
    my $item_get_div_nodes = shift;
    my $quest_div_node     = shift;

    $self->{PartyNo} = $party_no;

    $self->{IsPK} = ($self->isPractice($quest_div_node)) ? 1 : 0;
    $self->GetItemGetData($item_get_div_nodes);
    
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
    
    if(!$quest_div_node){ return 1;} # クエスト情報ノードがない場合、とりあえず敵の取得処理を実行する（ただし戦闘自体がないものと予想される）
    my $text = $quest_div_node->as_text;
    
    if($text =~ /練習試合を申し込んだ。.+?はそれに応じた。/){ return 1;}
    if($text =~ /PKを開始します。/){ return 1;}

    return 0;
}

#-----------------------------------#
#    ドロップデータ取得
#------------------------------------
#    引数｜名前データノード
#-----------------------------------#
sub GetItemGetData{
    my $self  = shift;
    my $item_get_div_nodes = shift;

    my $battler_num = 0;
    my $sook_num = 0;
    foreach my $e_no (keys(%{$self->{CommonDatas}{Party}{$self->{PartyNo}}})) { # 所属するEno一覧を取得
        foreach my $sub_no (keys(%{$self->{CommonDatas}{NickName}{$e_no}})){
            my $nickname = $self->{CommonDatas}{NickName}{$e_no}{$sub_no};
            # Enoを元に、サブキャラ全員の通り名を取得
            $self->{ENoSubNo}{$nickname} = [$e_no, $sub_no];
        }
    }

    foreach my $item_get_div_node (@$item_get_div_nodes){
        my $b_nodes = &GetNode::GetNode_Tag("b", \$item_get_div_node);

        if(scalar(@$b_nodes) < 3) {next;}

        my $nickname = $$b_nodes[0]->as_text; 
        my $enemy_id = $self->{CommonDatas}{EnemyName}->GetOrAddId($$b_nodes[1]->as_text);
        my $item_name = $$b_nodes[2]->as_text; 

        my $e_no   = (exists($self->{ENoSubNo}{$nickname}) && $self->{ENoSubNo}{$nickname}[0]) ? $self->{ENoSubNo}{$nickname}[0] : 0;
        my $sub_no = (exists($self->{ENoSubNo}{$nickname}) && $self->{ENoSubNo}{$nickname}[1]) ? $self->{ENoSubNo}{$nickname}[1] : 0;

        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $e_no, $sub_no, $enemy_id, $item_name, $self->{IsPK});
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
