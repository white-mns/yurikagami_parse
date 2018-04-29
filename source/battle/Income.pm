#===================================================================
#        収入一覧取得パッケージ
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
package Income;

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
				"money",
				"sundries",
                "exp",
                "is_pk",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/income_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $get_mn_exp_div_nodes = shift;
    my $quest_div_node     = shift;

    $self->{PartyNo} = $party_no;
    $self->{IsPK} = $self->isPCBattle($quest_div_node);

    $self->GetIncomeData($get_mn_exp_div_nodes);
    
    return;
}

#-----------------------------------#
#    対人戦かどうかの判定
#------------------------------------
#    引数｜クエスト情報ノード
#-----------------------------------#
sub isPCBattle{
    my $self      = shift;
    my $quest_div_node    = shift;
    
    if(!$quest_div_node){ return 1;} # クエスト情報ノードがない場合、とりあえず敵の取得処理を実行する（ただし戦闘自体がないものと予想される）
    my $text = $quest_div_node->as_text;
    
    if($text =~ /練習試合を申し込んだ。.+?はそれに応じた。/){ return 1;}
    if($text =~ /PKを開始します。/){ return 2;}

    return 0;
}

#-----------------------------------#
#    収入データ取得
#------------------------------------
#    引数｜収入データノード
#-----------------------------------#
sub GetIncomeData{
    my $self  = shift;
    my $get_mn_exp_div_nodes = shift;

    my $battler_num = 0;
    my $sook_num = 0;
    foreach my $e_no (keys(%{$self->{CommonDatas}{Party}{$self->{PartyNo}}})) { # 所属するEno一覧を取得
        foreach my $sub_no (keys(%{$self->{CommonDatas}{NickName}{$e_no}})){
            my $nickname = $self->{CommonDatas}{NickName}{$e_no}{$sub_no};
            # Enoを元に、サブキャラ全員の通り名を取得
            $self->{ENoSubNo}{$nickname} = [$e_no, $sub_no];
        }
    }

    foreach my $get_mn_exp_div_node (@$get_mn_exp_div_nodes){
        my ($e_no, $sub_no, $money, $sundries, $exp) = (0, 0, 0, 0, 0);

        my $ch_b_nodes = &GetNode::GetNode_Tag_Class("b", "ch", \$get_mn_exp_div_node);
        my $mn_b_nodes = &GetNode::GetNode_Tag_Class("b", "mn", \$get_mn_exp_div_node);
        my $zk_b_nodes = &GetNode::GetNode_Tag_Class("b", "zk", \$get_mn_exp_div_node);
        my $xp_b_nodes = &GetNode::GetNode_Tag_Class("b", "xp", \$get_mn_exp_div_node);

        my $nickname = $$ch_b_nodes[0]->as_text;
        
        $e_no   = (exists($self->{ENoSubNo}{$nickname}) && $self->{ENoSubNo}{$nickname}[0]) ? $self->{ENoSubNo}{$nickname}[0] : 0;
        $sub_no = (exists($self->{ENoSubNo}{$nickname}) && $self->{ENoSubNo}{$nickname}[1]) ? $self->{ENoSubNo}{$nickname}[1] : 0;

        $money    =  (scalar(@$mn_b_nodes)) ? $$mn_b_nodes[0]->as_text : 0; 
        $sundries =  (scalar(@$zk_b_nodes)) ? $$zk_b_nodes[0]->as_text : 0; 
        $exp      =  (scalar(@$xp_b_nodes)) ? $$xp_b_nodes[0]->as_text : 0;

        $money    =~ s/\D//g;
        $sundries =~ s/\D//g;
        $exp      =~ s/\D//g;
        
        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $e_no, $sub_no, $money, $sundries, $exp, $self->{IsPK});
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
