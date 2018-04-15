#===================================================================
#        ステータス取得パッケージ
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
package Status;

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
    
    $self->{CommonDatas}{CharacterJob} = {}; # 戦型-習得可能技一覧で使用するため共用変数に記録
    
    #初期化
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "e_no",
                "sub_no",
				"lv",
				"exp",
				"mexp",
				"job1",
				"job2",
				"hp",
				"mhp",
				"hp_rate",
				"mp",
				"mmp",
				"mp_rate",
				"sp",
				"str",
				"int",
				"tec",
				"agi",
				"def",
				"skill",
				"personality",
                "tribe",
				"money",
				"sundries",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/status_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,サブキャラ番号,ステータスノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $sub_no  = shift;
    my $stat_table_node = shift;
    
    $self->{ENo}   = $e_no;
    $self->{SubNo} = $sub_no;

    $self->GetStatusData($stat_table_node);
    
    return;
}
#-----------------------------------#
#    ステータスデータ取得
#------------------------------------
#    引数｜ステータスノード
#-----------------------------------#
sub GetStatusData{
    my $self  = shift;
    my $stat_table_node = shift;
    my ($lv, $exp, $mexp, $job1, $job2, $hp, $mhp, $hp_rate, $mp, $mmp, $mp_rate, $sp, $str, $int, $tec, $agi, $def, $skill, $personality, $tribe, $money, $sundries)
     = (0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0,0);

    my $sttitle_nodes  = &GetNode::GetNode_Tag_Class("td","sttitle", \$stat_table_node);
    my $div_post_nodes = &GetNode::GetNode_Tag_Class("div","post", \$$sttitle_nodes[0]);
    my $th_nodes       = &GetNode::GetNode_Tag("th", \$stat_table_node);
   
    foreach my $th_node (@$th_nodes){
		my $text = $th_node->as_text;
		
        if($text eq "Lv"){
			$lv = $th_node->right->as_text;
		}elsif($text eq "Exp"){
		    $th_node->right->as_text =~ m!(\d+)/(\d+)!;
		    $exp  = $1;
		    $mexp = $2;
		}elsif($text =~ /戦型/){
			$th_node->right->as_text =~ m!(\d:)*(.+)/(\d:)*(.+)!;
            $job1 = $self->{CommonDatas}{JobName}->GetOrAddId($2);
            $job2 = $self->{CommonDatas}{JobName}->GetOrAddId($4);

            $self->{CommonDatas}{CharacterJob}{$self->{ENo}."_".$self->{SubNo}}[0] = $job1;
            $self->{CommonDatas}{CharacterJob}{$self->{ENo}."_".$self->{SubNo}}[1] = $job2;
            $self->{CommonDatas}{CharacterJobName}{$self->{ENo}."_".$self->{SubNo}}[0] = $2; # 習得可能技でのハロウィン判定用

		}elsif($text eq "HP"){
			$th_node->right->as_text =~ m!(\d+)/(\d+)!;
			$hp = $1;
			$mhp = $2;
			if ($mhp > 0) {$hp_rate = $hp / $mhp;}
		}elsif($text eq "MP"){
			$th_node->right->as_text =~ m!(\d+)/(\d+)!;
			$mp = $1;
			$mmp = $2;
			if ($mmp > 0) {$mp_rate = $mp / $mmp;}
		}elsif($text eq "SP"){
			$sp = $th_node->right->as_text;
		}elsif($text eq "腕力"){
			$str = $th_node->right->as_text;
		}elsif($text eq "魔力"){
			$int = $th_node->right->as_text;
		}elsif($text eq "器用"){
			$tec = $th_node->right->as_text;
		}elsif($text eq "反応"){
			$agi = $th_node->right->as_text;
		}elsif($text eq "守護"){
			$def = $th_node->right->as_text;
		}elsif($text eq "熟練"){
			$skill = $th_node->right->as_text;
		}elsif($text eq "性格"){
            $personality = $self->{CommonDatas}{ProperName}->GetOrAddId($th_node->right->as_text);
		}elsif($text eq "種族"){
            $tribe = $self->{CommonDatas}{ProperName}->GetOrAddId($th_node->right->as_text);
		}elsif($text eq "金"){
			$money = $th_node->right->as_text;
			$money =~ s/Lem//;
		}elsif($text eq "雑貨"){
			$sundries = $th_node->right->as_text;
			$sundries =~ s/Lem//;
		}
	}

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $lv, $exp, $mexp, $job1, $job2, $hp, $mhp, $hp_rate, $mp, $mmp, $mp_rate, $sp, $str, $int, $tec, $agi, $def, $skill, $personality, $tribe, $money, $sundries);
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
