#===================================================================
#        所持技取得パッケージ
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
                "e_no",
                "sub_no",
                "skill_no",
                "skill_id",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/chara/skill_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,サブキャラ番号,技テーブルノード
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
#    技データ取得
#------------------------------------
#    引数｜技テーブルノード
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
        my $node_num = 0;

        $skill_no = $td_nodes[$node_num]->as_text;
        $node_num += 1;
        
        if($skill_no =~ /-/){ # 自動発動に番号割当
            $skill_no = $auto_no;
            $auto_no += 1;
        }elsif($skill_no =~ /i/){ # アイテム技は取得しない
            next;
        }

        my $skill_name = $td_nodes[$node_num]->as_text;
        $node_num += 1;

        if($td_nodes[$node_num]->as_text =~ /(\d+)\/(.+)/){
            $at = $1;
            my $ct_text = $2;
            $ct = ($ct_text =~ /\//) ? -2 : $ct_text; # 流星の舞など追撃を行うものは表示上で多段攻撃とする

        }else {
            $timing = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[2]->as_text);
        }
        $node_num += 1;

        my $mp_text = $td_nodes[$node_num]->as_text;
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
        $node_num += 1;

        if(scalar(@td_nodes)>6){ # 第10回更新より対象・射程・特性・属性が表記されたので、その有無に対応
            $target = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[$node_num]->as_text);
            $node_num += 1;

            $range = $td_nodes[$node_num]->as_text;
            $range = ($range =~ /-/)  ? -1 : $range;
            $range = ($range =~ /武/) ? -2 : $range;
            $node_num += 1;
       
            if($td_nodes[$node_num]->as_text =~ /(.+)\/(.+)/){
                my $span_nodes = &GetNode::GetNode_Tag("span", \$td_nodes[$node_num]);
                
                $property = $self->{CommonDatas}{ProperName}->GetOrAddId($$span_nodes[0]->as_text);
                $element  = $self->{CommonDatas}{ProperName}->GetOrAddId($$span_nodes[1]->as_text);
                $text = $td_nodes[$node_num+1]->as_text;

            }else{
                $text = $td_nodes[$node_num]->as_text;
            }
        }else{
            $text = $td_nodes[$node_num]->as_text;
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId([$skill_name, $at, $ct, $timing, $mp, $target, $range, $property, $element, $text]);
        
        my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $skill_no, $skill_id);
        $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @datas));


        # 戦闘時、ボスフラグ込での人数を出すために、通り名とボスフラグ込人数、臆病者人数を共通変数で記録する(通り名はプロフィール一覧で取得すt)
        if($skill_name eq "ボスフラグ"){
            my $title = $self->{CommonDatas}{NickName}{$self->{ENo}}{$self->{SubNo}};
            $self->{CommonDatas}{Battler}{$self->{ENo}}{$title} = 2;
        }
        if($skill_name eq "臆病者"){
            my $title = $self->{CommonDatas}{NickName}{$self->{ENo}}{$self->{SubNo}};
            $self->{CommonDatas}{Sook}{$self->{ENo}}{$title} = 1;
        }
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
