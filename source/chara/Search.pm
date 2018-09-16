#===================================================================
#        探索結果取得パッケージ
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
package Search;

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
    $self->{Datas}{Search}    = StoreData->new();
    
    my $header_list = "";
    $header_list = [
                "result_no",
                "generate_no",
                "last_result_no",
                "last_generate_no",
                "e_no",
                "sub_no",
                "main_no",
                "i_no",
                "i_name",
                "value",
    ];
    $self->{Datas}{Search}->Init($header_list);
    $self->{Datas}{Search}->SetOutputName( "./output/chara/search_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );

    $self->ReadLastData();
    return;
}

#-----------------------------------#
#    前回の更新番号・再更新番号を取得
#-----------------------------------#
sub ReadLastData(){
    my $self      = shift;
    
    $self->{LastResultNo} = $self->{ResultNo} - 1;    
    $self->{LastGenerateNo} = 0;    

    # 前回結果の確定版ファイルを探索
    for (my $i=5; $i>=0; $i--){
        my $file_name = "./output/chara/search_" . ($self->{LastResultNo}) . "_" . $i . ".csv" ;
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
#    引数｜e_no,サブキャラ番号,イベントノード
#-----------------------------------#
sub GetData{
    my $self    = shift;
    my $e_no    = shift;
    my $sub_no  = shift;
    my $event_div_nodes = shift;
    
    if($sub_no == 0) {return;} # メインキャラに探索はないため処理しない
    
    $self->{ENo}   = $e_no;
    $self->{SubNo} = $sub_no;

    $self->GetSearchData($event_div_nodes);
    
    return;
}
#-----------------------------------#
#    イベントデータ取得
#------------------------------------
#    引数｜イベントノード
#-----------------------------------#
sub GetSearchData{
    my $self  = shift;
    my $event_div_nodes = shift;

    if (!scalar(@$event_div_nodes)) {return;}

    my $h2_nodes = &GetNode::GetNode_Tag("h2", \$$event_div_nodes[0]);

    if ($$h2_nodes[0]->as_text ne "探索") {return;}

    my @children = $$event_div_nodes[0]->content_list();
    my $result_text = $children[2];

    foreach my $child ($$event_div_nodes[0]->content_list()){
        if($child) {
            my ($main_no, $get_i_no, $i_name, $value) = (0, -1, "", -99999);
            
            if($child =~ /HASH/ && $child->tag eq "b" && $child->attr("class") ne "ch") {
                # アイテム取得時の解析
                my $text = $child->as_text;

                if($text =~ /(\d+)Lem/){
                    $value = $1;

                }else{
                    # 取得したアイテムのINoを名前から照合。今回新規に取得したアイテムのみ対象
                    foreach my $i_no (keys %{$self->{CommonDatas}{NewItemData}{$self->{ENo}}}){
                        if($text eq $self->{CommonDatas}{NewItemData}{$self->{ENo}}{$i_no}){
                            $get_i_no = $i_no;
                            $value = $self->{CommonDatas}{NewItemPrize}{$self->{ENo}}{$i_no};
                            last;
                        }
                    }
                }
                if($get_i_no == -1 && $value == -99999){
                    $i_name = $text;

                }
                
                my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{LastResultNo}, $self->{LastGenerateNo}, $self->{ENo}, $self->{SubNo}, $main_no, $get_i_no, $i_name, $value);
                $self->{Datas}{Search}->AddData(join(ConstData::SPLIT, @datas));

            }elsif($child !~ /HASH/) {
                # Lemの取得・喪失時の解析
                if($child =~ /(\d+)Lem を入手した。/){
                    $value = $1;

                }elsif($child =~ /(\d+)Lem を落とした！/){
                    $value = $1+0;
                    $value *= -1;
                }elsif($child =~ /何も見つけられなかった。/){
                    $value = 0;
                }
                
                if($get_i_no == -1 && $value == -99999){
                    next;
                }

                my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{LastResultNo}, $self->{LastGenerateNo}, $self->{ENo}, $self->{SubNo}, $main_no, $get_i_no, $i_name, $value);
                $self->{Datas}{Search}->AddData(join(ConstData::SPLIT, @datas));

            }else{
                if($child->tag eq "br" || $child->tag eq "h2"){next;}
                if($child->tag eq "b" && $child->attr("class") eq "ch"){next;}

                print $child->tag . "/" . $child->as_text . "\n";
                $value = $child->as_text;
                
                my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{ENo}, $self->{SubNo}, $main_no, $get_i_no, $i_name, $value);
                $self->{Datas}{Search}->AddData(join(ConstData::SPLIT, @datas));
            }
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
