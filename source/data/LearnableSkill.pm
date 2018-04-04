#===================================================================
#        戦型-習得可能スキル対応取得パッケージ
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
package LearnableSkill;

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
    
    if(!defined $self->{CommonDatas}{CharacterJob}){print "!!\tCommonDatas_CharacterJob isn't defined! (EXE_CHARA_STATUS should be \"1\" in ConstData.pm)\n";} #
    $self->{LearnableSkill} = {};
    
    #初期化
    $self->{Datas}{Data}  = StoreData->new();
    my $header_list = "";
   
    $header_list = [
                "chara_type",
                "job_id",
                "skill_no",
                "sp",
                "skill_id",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/data/learnable_skill.csv" );
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
    my $gskl_div_node  = shift;
    
    $self->{ENo}   = $e_no;
    $self->{SubNo} = $sub_no;
    
    if(!defined $self->{CommonDatas}{CharacterJob}){return;}

    $self->GetLeanableSkillData($gskl_div_node);
    
    return;
}
#-----------------------------------#
#    アイテムデータ取得
#------------------------------------
#    引数｜アイテムノード
#-----------------------------------#
sub GetLeanableSkillData{
    my $self  = shift;
    my $gskl_div_node  = shift;

    my $skill_table_nodes = &GetNode::GetNode_Tag_Class("table","skill", \$gskl_div_node);
    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$$skill_table_nodes[0]);
    shift(@$tr_nodes);
   
    my $chara_type = ($self->{SubNo}>0) ? 1 : 0; # サブキャラの習得SPはメインと異なるために分離する

    foreach my $tr_node (@$tr_nodes){
        my @td_nodes = $tr_node->content_list();
        my ($skill_no, $skill_id, $at, $ct, $timing, $mp, $target, $range, $property, $element, $text)
         = (0,0,-1,-1,0,0,0,-1,0,0,"");
        my $node_num = 0;

        $skill_no = $td_nodes[$node_num]->as_text;
        
        my $job = $self->{CommonDatas}{CharacterJob}{$self->{ENo}."_".$self->{SubNo}}[int($skill_no / 17)];
        $skill_no = (($skill_no - 1 ) % 16) + 1;
        $node_num += 1;
        
        my $skill_name = $td_nodes[$node_num]->as_text;
        $node_num += 1;

        my $sp = $td_nodes[$node_num]->as_text;
        $node_num += 1;

        if(scalar(@td_nodes)>5){ # 戦型習得はカラム数が少ないため、その分岐
            if($td_nodes[$node_num]->as_text =~ /(\d+)\/(.+)/){
                $at = $1;
                my $ct_text = $2;
                $ct = ($ct_text =~ /\//) ? -2 : $ct_text; # 流星の舞など追撃を行うものは表示上で多段攻撃とする

            }else {
                $timing = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[3]->as_text);
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

            if(scalar(@td_nodes)>7){ # 第10回更新より対象・射程・特性・属性が表記されたので、その有無に対応
                $target = $self->{CommonDatas}{ProperName}->GetOrAddId($td_nodes[$node_num]->as_text);
                $node_num += 1;

                $range = $td_nodes[$node_num]->as_text;
                $range = ($range =~ /-/)  ? -1 : $range;
                $range = ($range =~ /武/) ? -2 : $range;
                $node_num += 1;
                
                if($td_nodes[$node_num]->as_text =~ /(.+)\/(.+)/){
                    my $span_nodes = &GetNode::GetNode_Tag("span", \$td_nodes[$node_num]);
                    
                    if(scalar(@$span_nodes)){ # 第10回、第11回はspanタグで色付けされていなかったため取得しない（後の更新結果で再取得するため）
                        $property = $self->{CommonDatas}{ProperName}->GetOrAddId($$span_nodes[0]->as_text);
                        $element  = $self->{CommonDatas}{ProperName}->GetOrAddId($$span_nodes[1]->as_text);
                    }
                    $text = $td_nodes[$node_num+1]->as_text;

                }else{ # 自動発動、常時発動の説明取得
                    $text = $td_nodes[$node_num]->as_text;
                }
            }else{ # 戦型習得の説明取得
                $text = $td_nodes[$node_num]->as_text;
            }
        }else{
            $timing = $self->{CommonDatas}{ProperName}->GetOrAddId("戦型取得");
            $text = $td_nodes[$node_num]->as_text;
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId([$skill_name, $at, $ct, $timing, $mp, $target, $range, $property, $element, $text]);
        
        $self->{LearnableSkill}{$chara_type}{$job}{$skill_no} = [$chara_type, $job, $skill_no, $sp, $skill_id];
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
    
    foreach my $chara_type (sort{$a <=> $b} keys(%{$self->{LearnableSkill}})){ # 習得可能スキルの出力データへの変換
        foreach my $job (sort{$a <=> $b} keys(%{$self->{LearnableSkill}{$chara_type}})){ # 習得可能スキルの出力データへの変換
            foreach my $skill_no (sort{$a <=> $b} keys(%{$self->{LearnableSkill}{$chara_type}{$job}})){
                $self->{Datas}{Data}->AddData(join(ConstData::SPLIT, @{$self->{LearnableSkill}{$chara_type}{$job}{$skill_no}}));
            }
        }
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
