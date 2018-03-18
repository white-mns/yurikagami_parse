#===================================================================
#        プロフィール取得パッケージ
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
package Profile;

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
				"nickname",
				"title",
				"job",
				"tribe",
				"sex",
				"age",
				"height",
				"weight",
    );

    $self->{Datas}{Data}  = $data;
    $self->{Datas}{Data}->Init(\@headerList);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/profile_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,名前データノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $sub_no  = shift;
    my $stat_table_node = shift;
    
    $self->{ENo}   = $e_no;
    $self->{SubNo} = $sub_no;

    $self->GetProfileData($stat_table_node);
    
    return;
}
#-----------------------------------#
#    プロフィールデータ取得
#------------------------------------
#    引数｜名前データノード
#-----------------------------------#
sub GetProfileData{
    my $self  = shift;
    my $stat_table_node = shift;
    my ($nickname, $title, $job, $tribe, $sex, $age, $height, $weight) = ("", "", "", "", "", "", "");

    my $sttitle_nodes  = &GetNode::GetNode_Tag_Class("td","sttitle", \$stat_table_node);
    my $div_post_nodes = &GetNode::GetNode_Tag_Class("div","post", \$$sttitle_nodes[0]);
    my $th_nodes       = &GetNode::GetNode_Tag("th", \$stat_table_node);
   
    if(@$div_post_nodes){
        $nickname = $$div_post_nodes[0]->as_text;
    }

    foreach my $th_node (@$th_nodes){
		my $text = $th_node->as_text;
		
        if($text eq "通名"){
			$title = $th_node->right->as_text;
		}elsif($text eq "職業"){
			$job = $th_node->right->as_text;
		}elsif($text eq "種族"){
            $tribe = $self->{CommonDatas}{ProperName}->GetOrAddId($th_node->right->as_text);
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

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $nickname, $title, $job, $tribe, $sex, $age, $height, $weight);
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
