#===================================================================
#        イベントフラグ取得パッケージ
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
package Event;

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
    $self->{Datas}{EventFlag}    = StoreData->new();
    $self->{Datas}{EventProceed} = StoreData->new();
    $self->{Datas}{NewEvent}     = StoreData->new();
    $self->{Datas}{AllEvent}     = StoreData->new();

    my $header_list = "";

    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "sub_no",
                "event_id",
                "flag_id",
                "text_id",
    ];
    $self->{Datas}{EventFlag}->Init($header_list);
    $self->{Datas}{EventFlag}->SetOutputName( "./output/chara/event_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "sub_no",
                "event_id",
                "last_flag_id",
                "flag_id",
    ];
    $self->{Datas}{EventProceed}->Init($header_list);
    $self->{Datas}{EventProceed}->SetOutputName( "./output/chara/event_proceed_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $header_list = [
                "result_no",
                "generate_no",
                "event_id",
                "flag_id",
    ];
    $self->{Datas}{NewEvent}->Init($header_list);
    $self->{Datas}{NewEvent}->SetOutputName( "./output/new/event_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllEvent}->Init($header_list);
    $self->{Datas}{AllEvent}->SetOutputName( "./output/new/all_event_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->ReadLastData();
    $self->ReadLastNewData();
 
    return;
}

#-----------------------------------#
#    前回のデータを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/chara/event_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $last_datas = []; 
        @$last_datas   = split(ConstData::SPLIT, $data_set);

        my $e_no  = $$last_datas[2];
        my $event = $$last_datas[4];
        my $flag  = $$last_datas[5];

        $self->{LastData}{$e_no}{$event} = $flag;
    }

    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastNewData(){
    my $self      = shift;
    
    my $file_name = "";
    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        $file_name = "./output/new/all_event_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_event_datas = []; 
        @$new_event_datas   = split(ConstData::SPLIT, $data_set);
        my $event = $$new_event_datas[2];
        my $flag = $$new_event_datas[3];
        if(!exists($self->{AllEvent}{$event."_".$flag})){
            $self->{AllEvent}{$event."_".$flag} = [$self->{ResultNo}, $self->{GenerateNo}, $event, $flag];
        }
    }

    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,サブキャラ番号,イベントノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $sub_no  = shift;
    my $evnt_div_node = shift;
    
    if($sub_no > 0) {return;} # サブキャラにイベント情報はないため処理しない
    
    $self->{ENo} = $e_no;
    $self->{SubNo} = $sub_no;

    $self->GetEventData($evnt_div_node);
    
    return;
}
#-----------------------------------#
#    イベントデータ取得
#------------------------------------
#    引数｜イベントノード
#-----------------------------------#
sub GetEventData{
    my $self  = shift;
    my $evnt_div_node = shift;

    my $event_table_nodes = &GetNode::GetNode_Tag_Attr("table", "class", "event", \$evnt_div_node);
    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$$event_table_nodes[0]);
    shift(@$tr_nodes);
   
    foreach my $tr_node (@$tr_nodes){
        # イベント情報の取得
        my @td_nodes = $tr_node->content_list();
        my ($event, $flag, $text) = (0,0);

        if(scalar(@td_nodes) < 3){ next;}

        $event = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[0]->as_text);
        $flag  = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[1]->as_text);
        $text  = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[2]->as_text);
        
        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $event, $flag, $text);
        $self->{Datas}{EventFlag}->AddData(join(ConstData::SPLIT, @datas));

        # イベント変更点の取得
        my $last_flag = exists($self->{LastData}{$self->{ENo}}{$event}) ? $self->{LastData}{$self->{ENo}}{$event} : 0;

        if($last_flag != $flag){
            my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $event, $last_flag, $flag);
            $self->{Datas}{EventProceed}->AddData(join(ConstData::SPLIT, @datas));
        }
        
        # 新出イベント状況の取得
        if(!exists($self->{AllEvent}{$event."_".$flag})){
            my @new_data = ($self->{ResultNo}, $self->{GenerateNo}, $event, $flag);
            $self->{Datas}{NewEvent}->AddData(join(ConstData::SPLIT, @new_data));

            $self->{AllEvent}{$event."_".$flag} = [$self->{ResultNo}, $self->{GenerateNo}, $event, $flag];
        }
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
    
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
