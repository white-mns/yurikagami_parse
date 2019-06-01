#===================================================================
#        戦型-習得可能技対応取得パッケージ
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
sub Init{
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
    
    $self->ReadLastData("./output/data/learnable_skill.csv");
    return;
}

#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    my $file_name = shift;
    
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $data = []; 
        @$data   = split(ConstData::SPLIT, $data_set);

        my $chara_type = $$data[0];
        my $job        = $$data[1];
        my $skill_no   = $$data[2];
        my $sp         = $$data[3];
        my $skill_id   = $$data[4];
        
        $self->{LearnableSkill}{$chara_type}{$job}{$skill_no} = [$chara_type, $job, $skill_no, $sp, $skill_id];
    }
    return;
}

#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜e_no,サブキャラ番号,未習得の技/戦型ノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $sub_no  = shift;
    my $gskl_div_node  = shift;
    
    $self->{ENo} = $e_no;
    $self->{SubNo} = $sub_no;

    if(!defined $self->{CommonDatas}{CharacterJob}){return;}

    $self->GetLeanableSkillData($gskl_div_node);
    
    return;
}
#-----------------------------------#
#    習得可能技データ取得
#------------------------------------
#    引数｜未習得の技/戦型ノード
#-----------------------------------#
sub GetLeanableSkillData{
    my $self  = shift;
    my $gskl_div_node  = shift;

    my $skill_table_nodes = &GetNode::GetNode_Tag_Attr("table", "class", "skill", \$gskl_div_node);
    my $tr_nodes = &GetNode::GetNode_Tag("tr", \$$skill_table_nodes[0]);
    shift(@$tr_nodes);
   
    my $chara_type = ($self->{SubNo}>0) ? 1 : 0; # サブキャラの習得SPはメインと異なるために分離する

    foreach my $tr_node (@$tr_nodes){
        my @td_nodes = $tr_node->content_list();
        my ($skill_no, $skill_id, $at, $ct, $timing, $mp, $target, $range, $property, $element, $text)
         = (0,0,-1,-1,0,0,0,-1,0,0,"");
        my $node_num = 0;

        $skill_no = $td_nodes[$node_num]->as_text;

        # 一部戦型は習得可能な技の数が16ではなく8のため、戦型1にあると他の戦型と比べて戦型2以降で習得可能な技noのNoが変わってしまう。
        # これを避けるために特殊な戦型はソース上で技数を指定する。(結果の内容からは機械的に判別できない)
        my $job_1_name = $self->{CommonDatas}{CharacterJobName}{$self->{ENo}."_".$self->{SubNo}}[0];
        my $job_has_skill_num = ($job_1_name eq "ハロウィン") ? 8 : 16;
        $job_has_skill_num = ($job_1_name eq "流れ者") ? 8 : $job_has_skill_num;
        $job_has_skill_num = ($job_1_name eq "作り手") ? 8 : $job_has_skill_num;
        $job_has_skill_num = ($job_1_name eq "標差し") ? 8 : $job_has_skill_num;
        
        my $job_num = ($skill_no > $job_has_skill_num) ? 1 : 0;
        my $job = $self->{CommonDatas}{CharacterJob}{$self->{ENo}."_".$self->{SubNo}}[$job_num];
        $skill_no = ($skill_no > $job_has_skill_num) ? $skill_no - $job_has_skill_num : $skill_no;
        $node_num += 1;
        
        my $skill_name = $td_nodes[$node_num]->as_text;
        $node_num += 1;

        my $sp = $td_nodes[$node_num]->as_text;
        $node_num += 1;

        if(scalar(@td_nodes)>5){ # カラム数で戦型習得と技習得を判定
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
        }else{
            $timing = $self->{CommonDatas}{ProperName}->GetOrAddId("戦型取得");
            $text = $td_nodes[$node_num]->as_text;
        }

        $skill_id = $self->{CommonDatas}{SkillData}->GetOrAddId(1, [$skill_name, $at, $ct, $timing, $mp, $target, $range, $property, $element, $text]);
        
        $self->{LearnableSkill}{$chara_type}{$job}{$skill_no} = [$chara_type, $job, $skill_no, $sp, $skill_id];
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
     
    foreach my $chara_type (sort{$a <=> $b} keys(%{$self->{LearnableSkill}})){ # 習得可能技の出力データへの変換
        foreach my $job (sort{$a <=> $b} keys(%{$self->{LearnableSkill}{$chara_type}})){ # 習得可能技の出力データへの変換
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
