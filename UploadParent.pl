#===================================================================
#    データベースへのアップロード
#-------------------------------------------------------------------
#        (C) 2018 @white_mns
#===================================================================

# モジュール呼び出し    ---------------#
require "./source/Upload.pm";
require "./source/lib/time.pm";

# パッケージの使用宣言    ---------------#
use strict;
use warnings;
require LWP::UserAgent;
use HTTP::Request;
use HTTP::Response;

# 変数の初期化    ---------------#
use ConstData_Upload;        #定数呼び出し

my $timeChecker = TimeChecker->new();

# 実行部    ---------------------------#
$timeChecker->CheckTime("start  \t");

&Main;

$timeChecker->CheckTime("end    \t");
$timeChecker->OutputTime();
$timeChecker = undef;

# 宣言部    ---------------------------#

sub Main {
    my $result_no = $ARGV[0];
    my $generate_no = $ARGV[1];
    my $upload = Upload->new();

    if(!defined($result_no) || !defined($generate_no)){
        print "error:empty result_no or generate_no";
        return;
    }

    $upload->DBConnect();
    
    if(ConstData::EXE_DATA){
        if(ConstData::EXE_DATA_PROPER_NAME){
            $upload->DeleteAll('proper_names');
            $upload->Upload("./output/data/proper_name.csv", 'proper_names');
        }
        if(ConstData::EXE_DATA_JOB_NAME){
            $upload->DeleteAll('job_names');
            $upload->Upload("./output/data/job_name.csv", 'job_names');
        }
        if(ConstData::EXE_DATA_SKILL_DATA){
            $upload->DeleteAll('skill_data');
            $upload->Upload("./output/data/skill_data.csv", 'skill_data');
        }
        if(ConstData::EXE_DATA_LEARNABLE_SKILL){
            $upload->DeleteAll('learnable_skills');
            $upload->Upload("./output/data/learnable_skill.csv", 'learnable_skills');
        }
        if(ConstData::EXE_DATA_PLACE_NAME){
            $upload->DeleteAll('place_names');
            $upload->Upload("./output/data/place_name.csv", 'place_names');
        }
        if(ConstData::EXE_DATA_ENEMY_NAME){
            $upload->DeleteAll('enemy_names');
            $upload->Upload("./output/data/enemy_name.csv", 'enemy_names');
        }
    }
    if(ConstData::EXE_NEW){
        if(ConstData::EXE_NEW_EVENT){
            $upload->DeleteSameResult('new_events', $result_no, $generate_no);
            $upload->Upload("./output/new/event_" . $result_no . "_" . $generate_no . ".csv", 'new_events');
        }
        if(ConstData::EXE_NEW_PLACE){
            $upload->DeleteSameResult('new_places', $result_no, $generate_no);
            $upload->Upload("./output/new/place_" . $result_no . "_" . $generate_no . ".csv", 'new_places');
        }
        if(ConstData::EXE_NEW_ENEMY){
            $upload->DeleteSameResult('new_enemies', $result_no, $generate_no);
            $upload->Upload("./output/new/enemy_" . $result_no . "_" . $generate_no . ".csv", 'new_enemies');
        }
    }
    if(ConstData::EXE_CHARA){
        if(ConstData::EXE_CHARA_NAME){
            $upload->DeleteSameResult('names', $result_no, $generate_no);
            $upload->Upload("./output/chara/name_" . $result_no . "_" . $generate_no . ".csv", 'names');
        }
        if(ConstData::EXE_CHARA_PROFILE){
            $upload->DeleteSameResult('profiles', $result_no, $generate_no);
            $upload->Upload("./output/chara/profile_" . $result_no . "_" . $generate_no . ".csv", 'profiles');
        }
        if(ConstData::EXE_CHARA_STATUS){
            $upload->DeleteSameResult('statuses', $result_no, $generate_no);
            $upload->Upload("./output/chara/status_" . $result_no . "_" . $generate_no . ".csv", 'statuses');
        }
        if(ConstData::EXE_CHARA_ITEM){
            $upload->DeleteSameResult('items', $result_no, $generate_no);
            $upload->Upload("./output/chara/item_" . $result_no . "_" . $generate_no . ".csv", 'items');
        }
        if(ConstData::EXE_CHARA_SKILL){
            $upload->DeleteSameResult('skills', $result_no, $generate_no);
            $upload->Upload("./output/chara/skill_" . $result_no . "_" . $generate_no . ".csv", 'skills');
        }
        if(ConstData::EXE_CHARA_EVENT){
            $upload->DeleteSameResult('events', $result_no, $generate_no);
            $upload->Upload("./output/chara/event_" . $result_no . "_" . $generate_no . ".csv", 'events');
        }
        if(ConstData::EXE_CHARA_EVENT_PROCEED){
            $upload->DeleteSameResult('event_proceeds', $result_no, $generate_no);
            $upload->Upload("./output/chara/event_proceed_" . $result_no . "_" . $generate_no . ".csv", 'event_proceeds');
        }
    }
    if(ConstData::EXE_BATTLE){
        if(ConstData::EXE_BATTLE_PARTY){
            $upload->DeleteSameResult('parties', $result_no, $generate_no);
            $upload->Upload("./output/battle/party_" . $result_no . "_" . $generate_no . ".csv", 'parties');
        }
        if(ConstData::EXE_BATTLE_PARTY_INFO){
            $upload->DeleteSameResult('party_infos', $result_no, $generate_no);
            $upload->Upload("./output/battle/party_info_" . $result_no . "_" . $generate_no . ".csv", 'party_infos');
        }
        if(ConstData::EXE_BATTLE_CURRENT_PLACE){
            $upload->DeleteSameResult('current_places', $result_no, $generate_no);
            $upload->Upload("./output/battle/current_place_" . $result_no . "_" . $generate_no . ".csv", 'current_places');
        }
        if(ConstData::EXE_BATTLE_SMITH){
            $upload->DeleteSameResult('smiths', $result_no, $generate_no);
            $upload->Upload("./output/battle/smith_" . $result_no . "_" . $generate_no . ".csv", 'smiths');
        }
        if(ConstData::EXE_BATTLE_ENEMY){
            $upload->DeleteSameResult('enemies', $result_no, $generate_no);
            $upload->Upload("./output/battle/enemy_" . $result_no . "_" . $generate_no . ".csv", 'enemies');
        }
        if(ConstData::EXE_BATTLE_ENEMY_PARTY_INFO){
            $upload->DeleteSameResult('enemy_party_infos', $result_no, $generate_no);
            $upload->Upload("./output/battle/enemy_party_info_" . $result_no . "_" . $generate_no . ".csv", 'enemy_party_infos');
        }
        if(ConstData::EXE_BATTLE_ITEM_GET){
            $upload->DeleteSameResult('item_gets', $result_no, $generate_no);
            $upload->Upload("./output/battle/item_get_" . $result_no . "_" . $generate_no . ".csv", 'item_gets');
        }
    }

    print "result_no:$result_no,generate_no:$generate_no\n";
    return;
}
