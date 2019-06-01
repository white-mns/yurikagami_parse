#===================================================================
#        現在地一覧取得パッケージ
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
sub Init{
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;
    
    #初期化
    $self->{Datas}{CurrentPlace} = StoreData->new();
    $self->{Datas}{NewPlace}     = StoreData->new();
    $self->{Datas}{AllPlace}     = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "place_id",
                "shop",
                "inn",
    ];

    $self->{Datas}{CurrentPlace}->Init($header_list);
    $self->{Datas}{CurrentPlace}->SetOutputName( "./output/battle/current_place_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $header_list = [
                "result_no",
                "generate_no",
                "place",
    ];
    $self->{Datas}{NewPlace}->Init($header_list);
    $self->{Datas}{NewPlace}->SetOutputName( "./output/new/place_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllPlace}->Init($header_list);
    $self->{Datas}{AllPlace}->SetOutputName( "./output/new/all_place_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->ReadLastNewData();
    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastNewData{
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--) {
        $file_name = "./output/new/all_place_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if (-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data) {
        my $new_event_datas = []; 
        @$new_event_datas   = split(ConstData::SPLIT, $data_set);
        my $place = $$new_event_datas[2];
        if (!exists($self->{AllPlace}{$place})) {
            $self->{AllPlace}{$place} = [$self->{ResultNo}, $self->{GenerateNo}, $place];
        }
    }

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜パーティ番号,現在地ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $party_no  = shift;
    my $map_div_node = shift;

    if(!$map_div_node) { return;}
    
    $self->{PartyNo} = $party_no;

    $self->GetCurrentPlaceData($map_div_node);
    
    return;
}

#-----------------------------------#
#    現在地データ取得
#------------------------------------
#    引数｜現在地ノード
#-----------------------------------#
sub GetCurrentPlaceData{
    my $self  = shift;
    my $map_div_node = shift;

    my ($place_id, $shop, $inn) = (0,0,0);

    my $h2_nodes  = &GetNode::GetNode_Tag("h2", \$map_div_node);
    my $h2_text = $$h2_nodes[0]->as_text;
    $h2_text =~ /現在地：(.+)/;
    $place_id = $self->{CommonDatas}{ProperName}->GetOrAddId($1);

    my $info_div_nodes  = &GetNode::GetNode_Tag_Attr("div", "class", "info", \$map_div_node);
    my $info_b_nodes  = &GetNode::GetNode_Tag("b", \$$info_div_nodes[0]);
    
    foreach my $info_b_node (@$info_b_nodes) {
        my @info_b_right = $info_b_node->right;
        if ($info_b_node->as_text eq "店") {
            if ($info_b_right[1]->tag eq "a") {
                my $shop_url = $info_b_right[1]->attr("href");
                $shop_url =~ /shop(\d+)\.html/;
                $shop = $1;
            }

        } elsif($info_b_node->as_text eq "宿") {
            $inn = ($info_b_right[0] =~ /利用可/) ? 1 : 0;
        }
    }

    $self->{Datas}{CurrentPlace}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $place_id, $shop, $inn) ));

    # 新出イベント状況の取得
    if (!exists($self->{AllPlace}{$place_id})) {
        my @new_data = ($self->{ResultNo}, $self->{GenerateNo}, $place_id);
        $self->{Datas}{NewPlace}->AddData(join(ConstData::SPLIT, @new_data));

        $self->{AllPlace}{$place_id} = [$self->{ResultNo}, $self->{GenerateNo}, $place_id];
    }
    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜
#-----------------------------------#
sub Output{
    my $self = shift;
     
    # 全地点情報の書き出し
    foreach my $place (sort{$a <=> $b} keys %{ $self->{AllPlace} } ) {
        $self->{Datas}{AllPlace}->AddData(join(ConstData::SPLIT, @{ $self->{AllPlace}{$place} }));
    }
   
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
