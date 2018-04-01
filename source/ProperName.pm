#===================================================================
#        固有名詞管理パッケージ
#-------------------------------------------------------------------
#            (C) 2018 @white_mns
#===================================================================


# パッケージの使用宣言    ---------------#
use strict;
use warnings;

use ConstData;
use HTML::TreeBuilder;
use source::lib::GetNode;

require "./source/lib/IO.pm";
require "./source/lib/time.pm";
require "./source/lib/NumCode.pm";

require "./source/data/StoreProperName.pm";
require "./source/data/StoreProperData.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package ProperName;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class        = shift;

  bless {
    Datas         => {},
    DataHandlers  => {},
    Methods       => {},
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init(){
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;

    #インスタンス作成
    $self->{DataHandlers}{ProperName} = StoreProperName->new();
    $self->{DataHandlers}{JobName}    = StoreProperName->new();
    $self->{DataHandlers}{PlaceName}  = StoreProperName->new();
    $self->{DataHandlers}{SkillData}  = StoreProperData->new();

    #他パッケージへの引き渡し用インスタンス
    $self->{CommonDatas}{ProperName} = $self->{DataHandlers}{ProperName};
    $self->{CommonDatas}{JobName}    = $self->{DataHandlers}{JobName};
    $self->{CommonDatas}{PlaceName}  = $self->{DataHandlers}{PlaceName};
    $self->{CommonDatas}{SkillData}  = $self->{DataHandlers}{SkillData};

    my $header_list = "";
    my $output_file = "";

    # 固有名詞の初期化
    $header_list = [
                "proper_id",
                "name",
    ];
    $output_file = "./output/data/". "proper_name" . ".csv";
    $self->{DataHandlers}{ProperName}->Init($header_list, $output_file," ");

    # 戦型名の初期化
    $header_list = [
                "job_id",
                "name",
    ];
    $output_file = "./output/data/". "job_name" . ".csv";
    $self->{DataHandlers}{JobName}->Init($header_list, $output_file," ");
    
    # 現在地情報の初期化
    $header_list = [
                "place_id",
                "name",
    ];
    $output_file = "./output/data/". "place_name" . ".csv";
    $self->{DataHandlers}{PlaceName}->Init($header_list, $output_file," ");

    # 技情報の初期化
    $header_list = [
                "skill_id",
                "name",
                "at",
                "ct",
                "timing",
                "mp",
                "target",
                "range",
                "property",
                "element",
                "text",
    ];
    $output_file = "./output/data/". "skill_data" . ".csv";
    $self->{DataHandlers}{SkillData}->Init($header_list, $output_file, [" ", "", "", "", "", "", "", "", "", ""]);
    
    return;
}

#-----------------------------------#
#   このパッケージでデータ解析はしない
#-----------------------------------#
#    
#-----------------------------------#
sub Execute{
    my $self        = shift;
    return ;
}

#-----------------------------------#
#    出力
#-----------------------------------#
#    引数｜ファイルアドレス
#-----------------------------------#
sub Output(){
    my $self = shift;
    foreach my $object( values %{ $self->{Datas} } ) {
        $object->Output();
    }
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Output();
    }
    return;
}

1;
