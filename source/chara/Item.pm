#===================================================================
#        所持アイテム取得パッケージ
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
package Item;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class = shift;
  my %datas = ();
  
  bless {
        Datas        => \%datas,
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init(){
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    my $data = StoreData->new();
    my @headerList = (
                "result_no",
                "generate_no",
                "e_no",
                "sub_no",
                "item_no",
                "name",
                "kind",
                "effect",
                "effect_num",
                "slash",
                "charge",
                "magic",
                "guard",
                "protect",
                "have_rest",
                "have_max",
                "prize",
                "ability",
                "equip",
    );

    $self->{Datas}{Data}  = $data;
    $self->{Datas}{Data}->Init(\@headerList);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/item_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,サブキャラ番号,アイテムノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $sub_no  = shift;
    my $item_table_node = shift;
    
    if($sub_no > 0) {return;} # サブキャラのアイテムはメインと共有のため処理しない
    
    $self->{ENo}   = $e_no;
    $self->{SubNo} = $sub_no;

    $self->GetItemData($item_table_node);
    
    return;
}
#-----------------------------------#
#    アイテムデータ取得
#------------------------------------
#    引数｜アイテムノード
#-----------------------------------#
sub GetItemData{
    my $self  = shift;
    my $item_table_node = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$item_table_node);
   
    foreach my $tr_node (@$tr_nodes){
        my @td_nodes = $tr_node->content_list();
        my ($item_no, $name, $kind, $effect, $effect_num, $slash, $charge, $magic, $guard, $protect, $have_rest, $have_max, $prize, $ability, $equip)
         = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);
        
        #名前欄処理
        my $nameData = $td_nodes[0]->as_text;
        $nameData =~ /(\d+)-(.+)/;
        $item_no = $1;
        $name = $2;
        
        #アイテム以外の解説欄時の処理
        unless($name){
            next;
        }
        if($nameData =~ /残り -*(\d+)枠/){
            last;
        }
        
        #種類欄処理 道具か否かで別処理
        my $kind_text = $td_nodes[1]->as_text;
        $kind = $self->{CommonDatas}{ProperName}->GetOrAddId($kind_text);

        my $have_td_num = 0;
        if($kind_text eq "道具"){
            my $dougu_text = $td_nodes[2]->as_text;
            $dougu_text =~ /(\D+)(\d*)/;
            $effect      = $self->{CommonDatas}{ProperName}->GetOrAddId($1);
            $effect_num  = $2;
            $have_td_num = 3;
        }else{
            $slash   = $td_nodes[2]->as_text;
            $charge  = $td_nodes[3]->as_text;
            $magic   = $td_nodes[4]->as_text;
            $guard   = $td_nodes[5]->as_text;
            $protect = $td_nodes[6]->as_text;
            $slash   =~ s/-/0/;
            $charge  =~ s/-/0/;
            $magic   =~ s/-/0/;
            $guard   =~ s/-/0/;
            $protect =~ s/-/0/;

            $have_td_num = 7;
        }
        
        #個数処理
        my $numData = $td_nodes[$have_td_num]->as_text;
        $numData   =~ m!(\d+)/(\d+)!;
        $have_rest = $1;
        $have_max  = $2;
        
        #価値
        $prize = $td_nodes[$have_td_num + 1]->as_text;
        #能力
        $ability = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[$have_td_num + 2]->as_text);
        #装備の有無
        my $equipmentData    = $tr_node->look_down('_tag', 'b');
        if($equipmentData){
            $equip = 1;
        }else{
            $equip = 0;
        }
        
        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $item_no, $name, $kind, $effect, $effect_num, $slash, $charge, $magic, $guard, $protect, $have_rest, $have_max, $prize, $ability, $equip);
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
