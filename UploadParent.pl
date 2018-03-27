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
    if(ConstData::EXE_NEW){
        if(ConstData::EXE_NEW_EVENT){
            $upload->DeleteSameResult('new_events', $result_no, $generate_no);
            $upload->Upload("./output/new/event_" . $result_no . "_" . $generate_no . ".csv", 'new_events');
        }
    }

    print "result_no:$result_no,generate_no:$generate_no\n";
    return;
}
