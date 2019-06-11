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
                "event",
                "flag",
                "text",
    ];
    $self->{Datas}{EventFlag}->Init($header_list);
    $self->{Datas}{EventFlag}->SetOutputName( "./output/chara/event_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "sub_no",
                "event",
                "last_flag",
                "flag",
    ];
    $self->{Datas}{EventProceed}->Init($header_list);
    $self->{Datas}{EventProceed}->SetOutputName( "./output/chara/event_proceed_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $header_list = [
                "result_no",
                "generate_no",
                "event",
                "flag",
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
#    引数｜e_no,サブキャラ番号,ステータステーブルノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $sub_no  = shift;
    my $stat_table_node = shift;
    
    $self->{ENo} = $e_no;
    $self->{SubNo} = $sub_no;

    $self->GetProfileData($stat_table_node);
    
    return;
}
#-----------------------------------#
#    プロフィールデータ取得
#------------------------------------
#    引数｜ステータステーブルノード
#-----------------------------------#
sub GetProfileData{
    my $self  = shift;
    my $stat_table_node = shift;
    my ($nickname, $title, $job, $sex, $age, $height, $weight) = ("", "", "", "", "", "", "");

    my $sttitle_nodes  = &GetNode::GetNode_Tag_Attr("td", "class", "sttitle", \$stat_table_node);
    my $div_post_nodes = &GetNode::GetNode_Tag_Attr("div","class", "post",    \$$sttitle_nodes[0]);
    my $th_nodes       = &GetNode::GetNode_Tag("th", \$stat_table_node);
   
    if(@$div_post_nodes){
        $title = $$div_post_nodes[0]->as_text;
    }

    foreach my $th_node (@$th_nodes){
		my $text = $th_node->as_text;
		
        if($text eq "通名"){
			$nickname = $th_node->right->as_text;
		}elsif($text eq "職業"){
			$job = $th_node->right->as_text;
		}elsif($text eq "性別"){
			$sex = $th_node->right->as_text;
		}elsif($text eq "年齢"){
			$age = $th_node->right->as_text;
		}elsif($text eq "身長"){
			$height = $th_node->right->as_text;
		}elsif($text eq "体重"){
			$weight = $th_node->right->as_text;
		}
	}

    $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, ($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $nickname, $title, $job, $sex, $age, $height, $weight) ));

    # 戦闘時、ボスフラグ込での人数を出すために、通り名とボスフラグ込人数を共通変数で記録する(ボスフラグの有無はスキル一覧で改めて取得する)
    $self->{CommonDatas}{NickName}{$self->{ENo}}{$self->{SubNo}} = $nickname;
    $self->{CommonDatas}{Battler}{$self->{ENo}}{$nickname} = 1;

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
