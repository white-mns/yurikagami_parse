#===================================================================
#        定数設定
#-------------------------------------------------------------------
#            (C) 2019 @white_mns
#===================================================================

# パッケージの定義    ---------------#    
package ConstData;

# パッケージの使用宣言    ---------------#
use strict;
use warnings;

# 定数宣言    ---------------#
    use constant SPLIT => "\t"; # 区切り文字

# ▼ 実行制御 =============================================
#      実行する場合は 1 ，実行しない場合は 0 ．
    
    use constant EXE_ALLRESULT  => 1;         # 0=> 部分探索(ex:1～10) 1=> 全結果探索
        use constant FLAGMENT_START    => 1;    #部分探索開始
        use constant FLAGMENT_END      => 1;    #部分探索終了
    
    use constant EXE_CHARA          => 1;
        use constant EXE_CHARA_NAME           => 1;
        use constant EXE_CHARA_PROFILE        => 1;
        use constant EXE_CHARA_STATUS         => 1;
        use constant EXE_CHARA_ITEM           => 1;
        use constant EXE_CHARA_SKILL          => 1;
        use constant EXE_CHARA_EVENT          => 1;
        use constant EXE_CHARA_SEARCH         => 1;
        use constant EXE_DATA_LEARNABLE_SKILL => 1;
    use constant EXE_BATTLE         => 1;
        use constant EXE_BATTLE_PARTY         => 1;
        use constant EXE_BATTLE_PARTY_INFO    => 1;
        use constant EXE_BATTLE_CURRENT_PLACE => 1;
        use constant EXE_BATTLE_ITEM_GET      => 1;
        use constant EXE_BATTLE_ENEMY         => 1;
        use constant EXE_BATTLE_RESULT        => 1;
        use constant EXE_BATTLE_SMITH         => 1;
1;
