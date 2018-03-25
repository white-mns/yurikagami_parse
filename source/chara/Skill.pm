#===================================================================
#        所持スキル取得パッケージ
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
package Skill;

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
                "skill_no",
                "skill_id",
    );

    $self->{Datas}{Data}  = $data;
    $self->{Datas}{Data}->Init(\@headerList);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/skill_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
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
    my $skill_table_node = shift;
    
    $self->{ENo}   = $e_no;
    $self->{SubNo} = $sub_no;

    $self->GetSkillData($skill_table_node);
    
    return;
}
#-----------------------------------#
#    アイテムデータ取得
#------------------------------------
#    引数｜アイテムノード
#-----------------------------------#
sub GetSkillData{
    my $self  = shift;
    my $skill_table_node = shift;

    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$skill_table_node);
    my $auto_no  = 10000;
    shift(@$tr_nodes);
   
    foreach my $tr_node (@$tr_nodes){
        my @td_nodes = $tr_node->content_list();
        my ($skill_no, $skill_id, $at, $ct, $timing, $mp, $target, $range, $property, $element, $text)
         = (0,0,-1,-1,0,0,0,-1,0,0,"");

        
        #名前欄処理
        $skill_no = $td_nodes[0]->as_text;
        
        if($skill_no =~ /-/){ # 自動発動に番号割当
            $skill_no = $auto_no;
            $auto_no += 1;
        }elsif($skill_no =~ /i/){ # アイテム技は取得しない
            next;
        }

        my $skill_name = $td_nodes[1]->as_text;

        if($td_nodes[2]->as_text =~ /(\d+)\/(.+)/){
            $at = $1;
            my $ct_text = $2;
            $ct = ($ct_text =~ /\//) ? -2 : $ct_text; # 流星の舞など追撃を行うものは表示上で多段攻撃とする

        }else {
            $timing = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[2]->as_text);
        }

        my $mp_text = $td_nodes[3]->as_text;
        if($mp_text =~ /\+/){ # 流星の舞、ベルセルクソウル等に対応
            if($mp_text =~ /\./){
                $mp = -1;

            }else{
                foreach my $one_mp ( split(/\+/,$mp_text) ){
                   $mp += $one_mp;
               }
            }
        }else{
            $mp = $mp_text;
        }

        $target = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[4]->as_text);
        $range = $td_nodes[5]->as_text;
        $range = ($range =~ /-/)  ? -1 : $range;
        $range = ($range =~ /武/) ? -2 : $range;
        
        if($td_nodes[6]->as_text =~ /(.+)\/(.+)/){
            my $span_nodes = &GetNode::GetNode_Tag("span", \$td_nodes[6]);
            
            $property = $self->{CommonDatas}{ProperName}->GetOrAddId($$span_nodes[0]->as_text);
            $element  = $self->{CommonDatas}{ProperName}->GetOrAddId($$span_nodes[1]->as_text);
            $text = $td_nodes[7]->as_text;

        }else{
            $text = $td_nodes[6]->as_text;
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId([$skill_name, $at, $ct, $timing, $mp, $target, $range, $property, $element, $text]);
        
        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $skill_no, $skill_id);
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
