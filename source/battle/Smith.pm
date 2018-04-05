#===================================================================
#        鍛冶結果一覧取得パッケージ
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
package Smith;

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
                "last_result_no",
                "last_generate_no",
                "party_no",
                "e_no",
                "sub_no",
                "result_i_no",
                "source_i_no",
                "main_material_i_no",
                "sub_material_1_i_no",
                "sub_material_2_i_no",
                "sub_material_3_i_no",
                "sub_material_4_i_no",
                "main_material_name_id",
                "sub_material_1_name_id",
                "sub_material_2_name_id",
                "sub_material_3_name_id",
                "sub_material_4_name_id",
    ];

    $self->{Datas}{Data}->Init($header_list);
    
    #出力ファイル設定
    $self->{Datas}{Data}->SetOutputName( "./output/battle/smith_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $self->ReadLastData();
    return;
}
#-----------------------------------#
#    既存データを読み込む
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    
    $self->{LastResultNo} = $self->{ResultNo} - 1;    
    $self->{LastGenerateNo} = 0;    

    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        my $file_name = "./output/battle/smith_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {
            $self->{LastGenerateNo} = $i;    
            last;
        }
    }
   
    return;
}
#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜パーティ番号,鍛冶情報データノード
#-----------------------------------#
sub GetData{
    my $self      = shift;
    my $party_no  = shift;
    my $smith_div_nodes = shift;
    
    $self->{PartyNo} = $party_no;

    $self->GetSmithData($smith_div_nodes);
    
    return;
}
#-----------------------------------#
#    鍛冶データ取得
#------------------------------------
#    引数｜鍛冶情報データノード
#-----------------------------------#
sub GetSmithData{
    my $self  = shift;
    my $smith_div_nodes = shift;

    foreach my $smith_div_node (@$smith_div_nodes){
        my ($e_no, $result_i_no, $source_i_no, $main_material_i_no, $sub_material_1_i_no, $sub_material_2_i_no, $sub_material_3_i_no, $sub_material_4_i_no,
            $main_material_name_id, $sub_material_1_name_id, $sub_material_2_name_id, $sub_material_3_name_id, $sub_material_4_name_id) =
           (0,0,0,0,0,0,0,0,0,0,0,0,0);
        my @sub_material_i_nos = (\$sub_material_1_i_no, \$sub_material_2_i_no, \$sub_material_3_i_no, \$sub_material_4_i_no);
        my @sub_material_name_ids = (\$sub_material_1_name_id, \$sub_material_2_name_id, \$sub_material_3_name_id, \$sub_material_4_name_id);

        my $smith_div_text = $smith_div_node->as_text;
        $smith_div_text =~ s/^(.+?作成した。).+$/$1/;
        $smith_div_text =~ s/^(.+?無理だった。).+$/$1/;

        $result_i_no = ($smith_div_text =~ /無理だった。/) ? -1 : 0;
        
        if($smith_div_text =~ /\(ENo\.(\d+)\)/){
            $e_no = $1;
        }
        my $i = 0;
        # 素材Inoの取得
        if(my @materials = $smith_div_text =~ /\(INo\.(\d+)\)/g){
            $main_material_i_no = shift(@materials);

            # サブ素材Inoの取得
            foreach my $material (@materials){
                ${$sub_material_i_nos[$i]} = $material;
                $i += 1;
            }
        }
        
        #  太字要素から、作成装備と参考装備名、素材名を取得
        #  smish get のdiv要素は正しく閉じられていないため、content_listで次のdiv要素(鍛冶後の別の行動)まで取得する
        my $it_b_nodes  = [];
        foreach my $child ($smith_div_node->content_list()){
            if($child && $child =~ /HASH/ && $child->tag eq "b" && $child->attr("class") eq "it"){
                push (@$it_b_nodes, $child);
            }
        }

        my $source_node = shift(@$it_b_nodes);
        my $result_node = pop(@$it_b_nodes);
        my $main_material_node = shift(@$it_b_nodes);

        # 装備のINoを名前から照合
        foreach my $i_no (keys %{$self->{CommonDatas}{ItemData}{$e_no}}){
            if($source_node->as_text eq $self->{CommonDatas}{ItemData}{$e_no}{$i_no}){
                $source_i_no = $i_no;
            }
        }
        if($source_i_no == 0){ # 作成後送品していた場合など、アイテム欄に残っていない場合は前回のアイテム欄と照合する
            foreach my $i_no (keys %{$self->{CommonDatas}{ItemLastData}{$e_no}}){
                if($source_node->as_text eq $self->{CommonDatas}{ItemLastData}{$e_no}{$i_no}){
                    $source_i_no = $i_no;
                }
            }
        }
        foreach my $i_no (keys %{$self->{CommonDatas}{SmithItemData}{$e_no}}){
            if($result_node->as_text eq $self->{CommonDatas}{SmithItemData}{$e_no}{$i_no}){
                $result_i_no = $i_no;
            }
        }

        # 素材INoの取得
        $main_material_name_id = $self->{CommonDatas}{ProperName}->GetOrAddId($main_material_node->as_text);

        $i = 0;
        foreach my $it_b_node (@$it_b_nodes){
            ${$sub_material_name_ids[$i]} = $self->{CommonDatas}{ProperName}->GetOrAddId($it_b_node->as_text);
            $i += 1;
        }

        my @datas=($self->{ResultNo}, $self->{GenerateNo},$self->{LastResultNo}, $self->{LastGenerateNo}, $self->{PartyNo}, $e_no, 0,
            $result_i_no, $source_i_no, $main_material_i_no, $sub_material_1_i_no, $sub_material_2_i_no, $sub_material_3_i_no, $sub_material_4_i_no,
            $main_material_name_id, $sub_material_1_name_id, $sub_material_2_name_id, $sub_material_3_name_id, $sub_material_4_name_id);
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
