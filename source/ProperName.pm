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
  my %datas        = ();
  my %dataHandlers = ();
  my %methods      = ();

  bless {
    Datas         => \%datas,
    DataHandlers  => \%dataHandlers,
    Methods       => \%methods,
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

    #他パッケージへの引き渡し用インスタンス
    $self->{CommonDatas}{ProperName} = $self->{DataHandlers}{ProperName};
    $self->{CommonDatas}{JobName}    = $self->{DataHandlers}{JobName};

    my $header_list = "";
    my $output_file = "";

    $header_list = [
                "proper_id",
                "name",
    ];
    $output_file = "./output/data/". "proper_name" . ".csv";
    $self->{DataHandlers}{ProperName}->Init($header_list, $output_file," ");

    $header_list = [
                "job_id",
                "name",
    ];
    $output_file = "./output/data/". "job_name" . ".csv";
    $self->{DataHandlers}{JobName}->Init($header_list, $output_file," ");

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
