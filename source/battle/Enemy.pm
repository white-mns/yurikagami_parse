#===================================================================
#        敵情報一覧取得パッケージ
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
package Enemy;

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
    $self->{Datas}{EnemyPartyInfo} = StoreData->new();
    $self->{Datas}{Enemy}          = StoreData->new();
    $self->{Datas}{NewEnemy}       = StoreData->new();
    $self->{Datas}{AllEnemy}       = StoreData->new();

    my $header_list = "";
   
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "enemy_num",
    ];
    $self->{Datas}{EnemyPartyInfo}->Init($header_list);
    $self->{Datas}{EnemyPartyInfo}->SetOutputName( "./output/battle/enemy_party_info_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $header_list = [
                "result_no",
                "generate_no",
                "party_no",
                "enemy",
                "suffix",
    ];
    $self->{Datas}{Enemy}->Init($header_list);
    $self->{Datas}{Enemy}         ->SetOutputName( "./output/battle/enemy_"       . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $header_list = [
                "result_no",
                "generate_no",
                "enemy",
    ];
    $self->{Datas}{NewEnemy}->Init($header_list);
    $self->{Datas}{NewEnemy}->SetOutputName( "./output/new/enemy_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    $self->{Datas}{AllEnemy}->Init($header_list);
    $self->{Datas}{AllEnemy}->SetOutputName( "./output/new/all_enemy_" . $self->{ResultNo} . "_" . $self->{GenerateNo} . ".csv" );
    
    $self->ReadLastNewData();

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
        $file_name = "./output/new/all_enemy_" . ($self->{ResultNo} - 1) . "_" . $i . ".csv" ;
        if(-f $file_name) {last;}
    }
    
    #既存データの読み込み
    my $content = &IO::FileRead ( $file_name );
    
    my @file_data = split(/\n/, $content);
    shift (@file_data);
    
    foreach my  $data_set(@file_data){
        my $new_enemy_datas = []; 
        @$new_enemy_datas   = split(ConstData::SPLIT, $data_set);
        my $enemy = $$new_enemy_datas[2];
        if(!exists($self->{AllEnemy}{$enemy})){
            $self->{AllEnemy}{$enemy} = [$self->{ResultNo}, $self->{GenerateNo}, $enemy];
        }
    }

    return;
}
#-----------------------------------#
#    データ取得
#------------------------------------
#    引数｜パーティ番号,キャラ情報データノード,クエスト情報ノード
#-----------------------------------#
sub GetData{
    my $self      = shift;
    my $party_no  = shift;
    my $bstat_table_nodes = shift;
    my $quest_div_node    = shift;
    
    $self->{PartyNo} = $party_no;
    $self->{Enemy}  = {};

    $self->{isPK} = ($self->isPractice($quest_div_node)) ? 1 : 0;
    $self->GetEnemyData($bstat_table_nodes);
    
    return;
}

#-----------------------------------#
#    対人戦かどうかの判定
#------------------------------------
#    引数｜クエスト情報ノード
#-----------------------------------#
sub isPractice{
    my $self      = shift;
    my $quest_div_node    = shift;
    
    if(!$quest_div_node){ return 1;} # クエスト情報ノードがない場合、とりあえず敵の取得処理を実行する（ただし戦闘自体がないものと予想される）
    my $text = $quest_div_node->as_text;
    
    if($text =~ /練習試合を申し込んだ。.+?はそれに応じた。/){ return 1;}
    if($text =~ /PKを開始します。/){ return 1;}

    return 0;
}

#-----------------------------------#
#    敵データ取得
#------------------------------------
#    引数｜キャラ情報データノード
#-----------------------------------#
sub GetEnemyData{
    my $self  = shift;
    my $bstat_table_nodes = shift;

    my $enemy_num = 0;

    foreach my $bstat_table_node (@$bstat_table_nodes) {
        my $vspt_tr_nodes  = &GetNode::GetNode_Tag_Class("tr","vspt", \$bstat_table_node);
        foreach my $vspt_tr_node (@$vspt_tr_nodes){
            my $td_nodes = &GetNode::GetNode_Tag("td", \$vspt_tr_node);

            my $enemy_full_name = $$td_nodes[0]->as_text; 
            my $enemy_name = $enemy_full_name;
            my $suffix     = "";
            if($enemy_full_name =~ /(.+?) (.{1,3}$)/){
                $enemy_name = $1;
                $suffix = $2;
            }
            my $enemy_id = $self->{CommonDatas}{EnemyName}->GetOrAddId($enemy_name);

            if(!exists($self->{Enemy}{$enemy_full_name})){ 
                $enemy_num += 1;

                my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $enemy_id, $suffix);
                $self->{Datas}{Enemy}->AddData(join(ConstData::SPLIT, @datas));
            }

            $self->{Enemy}{$enemy_full_name} = $enemy_full_name;
    
            # 新出敵の取得
            if(!$self->{isPK} && !exists($self->{AllEnemy}{$enemy_id})){
                my @new_data = ($self->{ResultNo}, $self->{GenerateNo}, $enemy_id);
                $self->{Datas}{NewEnemy}->AddData(join(ConstData::SPLIT, @new_data));

                $self->{AllEnemy}{$enemy_id} = [$self->{ResultNo}, $self->{GenerateNo}, $enemy_id];
            }
        }
    }

    my @datas=($self->{ResultNo}, $self->{GenerateNo}, $self->{PartyNo}, $enemy_num);
    $self->{Datas}{EnemyPartyInfo}->AddData(join(ConstData::SPLIT, @datas));

    return;
}

#-----------------------------------#
#    出力
#------------------------------------
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output(){
    my $self = shift;
    
    # 全敵情報の書き出し
    foreach my $enemy (sort{$a <=> $b} keys %{ $self->{AllEnemy} } ) {
        $self->{Datas}{AllEnemy}->AddData(join(ConstData::SPLIT, @{ $self->{AllEnemy}{$enemy} }));
    }

    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    return;
}
1;
