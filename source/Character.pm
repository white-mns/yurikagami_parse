#===================================================================
#        キャラステータス解析パッケージ
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

require "./source/chara/Name.pm";

use ConstData;        #定数呼び出し

#------------------------------------------------------------------#
#    パッケージの定義
#------------------------------------------------------------------#
package Character;

#-----------------------------------#
#    コンストラクタ
#-----------------------------------#
sub new {
  my $class        = shift;
  my %datas        = ();
  my %dataHandlers = ();
  my %methods      = ();

  bless {
    Datas          => \%datas,
    DataHandlers   => \%dataHandlers,
    Methods        => \%methods,
    ResultNo      => "",
    GenerateNo    => "",
  }, $class;
}

#-----------------------------------#
#    初期化
#-----------------------------------#
sub Init(){
    my $self = shift;
    ($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas}) = @_;

    #インスタンス作成
    if(ConstData::EXE_CHARA_NAME)          { $self->{DataHandlers}{Name}         = Name->new();}

    #初期化処理
    foreach my $object( values %{ $self->{DataHandlers} } ) {
        $object->Init($self->{ResultNo}, $self->{GenerateNo}, $self->{CommonDatas});
    }
    
    return;
}

#-----------------------------------#
#    圧縮結果から詳細データファイルを抽出
#-----------------------------------#
#    
#-----------------------------------#
sub Execute{
    my $self        = shift;

    print "read files...\n";

    my $start = 1;
    my $end   = 0;
    my $directory = './data/utf/turn' . $self->{ResultNo} . '_' . $self->{GenerateNo};
    if(ConstData::EXE_ALLRESULT){
        #結果全解析
        $end = GetFileNo($directory,"status");
    }else{
        #指定範囲解析
        $start = ConstData::FLAGMENT_START;
        $end   = ConstData::FLAGMENT_END;
    }

    print "$start to $end\n";

    for(my $e_no=$start; $e_no<=$end; $e_no++){
        if($e_no % 10 == 0){print $e_no . "\n"};

        $self->ParsePage($directory."/status".$e_no.".html",$e_no ,0);
        # サブキャラの判定
        for(my $f_no=1;$f_no<=3;$f_no++){
            $self->ParsePage($directory."/status".$e_no."_".$f_no.".html",$e_no ,$f_no);
        }
    }
    
    return ;
}
#-----------------------------------#
#       ファイルを解析
#-----------------------------------#
#    引数｜ファイル名
#    　　　ENo
#    　　　FNo
##-----------------------------------#
sub ParsePage{
    my $self        = shift;
    my $file_name   = shift;
    my $e_no        = shift;
    my $f_no        = shift;

    #結果の読み込み
    my $content = "";
    $content = &IO::FileRead($file_name);

    if(!$content){ return;}

    $content = &NumCode::EncodeEscape($content);
        
    #スクレイピング準備
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($content);

    my $sttitle_nodes   = &GetNode::GetNode_Tag_Class("td","sttitle", \$tree);

    # データリスト取得
    if(exists($self->{DataHandlers}{Name}))         {$self->{DataHandlers}{Name}->GetData($e_no, $f_no, $$sttitle_nodes[0])};

    $tree = $tree->delete;
}

#-----------------------------------#
#       該当ファイル数を取得
#-----------------------------------#
#    引数｜ディレクトリ名
#    　　　ファイル接頭辞
##-----------------------------------#
sub GetFileNo{
    my $directory   = shift;
    my $prefix    = shift;

    #ファイル名リストを取得
    my @fileList = grep { -f } glob("$directory/$prefix*.html");

    my $max= 0;
    foreach(@fileList){
        $_ =~ /$prefix(\d+).html/;
        if($max < $1) {$max = $1;}
    }
    return $max
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
