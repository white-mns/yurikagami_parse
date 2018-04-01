#===================================================================
#        現在地一覧取得パッケージ
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
package CurrentPlace;

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
                "place",
                "shop",
                "inn",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/current_place_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜パーティ番号,マップ情報
#-----------------------------------#
sub GetData{
    my $self      = shift;
    my $party_no  = shift;
    my $map_div_node = shift;

    if(!$map_div_node) { return;}
    
    $self->{PartyNo} = $party_no;

    $self->GetPartyData($map_div_node);
    
    return;
}
#-----------------------------------#
#    現在地データ取得
#------------------------------------
#    引数｜キャラ情報データノード
#-----------------------------------#
sub GetPartyData{
    my $self  = shift;
    my $map_div_node = shift;

    my ($place_id, $shop, $inn) = (0,0,0);

    my $h2_nodes  = &GetNode::GetNode_Tag("h2", \$map_div_node);
    my $h2_text = $$h2_nodes[0]->as_text;
    $h2_text =~ /現在地：(.+)/;
    $place_id = $self->{CommonDatas}{PlaceName}->GetOrAddId($1);

    my $info_div_nodes  = &GetNode::GetNode_Tag_Class("div", "info", \$map_div_node);
    my $info_b_nodes  = &GetNode::GetNode_Tag("b", \$$info_div_nodes[0]);
    
    foreach my $info_b_node (@$info_b_nodes){
        my @info_b_right = $info_b_node->right;
        if ($info_b_node->as_text eq "店"){
            if ($info_b_right[1]->tag eq "a"){
                my $shop_url = $info_b_right[1]->attr("href");
                $shop_url =~ /shop(\d+)\.html/;
                $shop = $1;
            }

        }elsif($info_b_node->as_text eq "宿"){
            $inn = ($info_b_right[0] =~ /利用可/) ? 1 : 0;
        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $place_id, $shop, $inn);
    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));

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
