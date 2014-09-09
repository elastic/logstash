# encoding: utf-8
require "test_utils"

# Test suite for the grok patterns defined in patterns/google-app-engine
# For each pattern:
#  - a sample is considered valid i.e. "should match"  where message == result
#  - a sample is considered invalid i.e. "should NOT match"  where message != result
#
describe "google app engine grok pattern" do
    extend LogStash::RSpec
    
    describe "GAEFULLLOG" do
        config <<-CONFIG
        filter {
            grok {
                match => { "message" => "%{GAEFULLLOG:result}" }
            }
        }
        CONFIG
        
        context "should match" do
            [
            "54.240.145.210 - - [09/Sep/2014:00:00:00 -0700] \"GET /image.jpeg HTTP/1.1\" 200 14209 - \"Amazon CloudFront\" \"mydomain.com\" ms=202 cpu_ms=103 cpm_usd=0.001588 instance=00c61b117cd582cbba5e6d6c204dd63bb2e930f0 app_engine_release=1.9.11",
            "54.240.145.210 - - [09/Sep/2014:00:00:00 -0700] \"GET /image.jpeg HTTP/1.1\" 200 14209 - \"Amazon CloudFront\" \"mydomain.com\" ms=202 cpu_ms=103 cpm_usd=0.001588 instance=00c61b117cd582cbba5e6d6c204dd63bb2e930f0 app_engine_release=1.9.9",
            "0.1.0.3 - - [09/Sep/2014:00:06:38 -0700] \"GET /_ah/warmup HTTP/1.1\" 200 0 - - \"fulldomain.appspot.com\" ms=7425 cpu_ms=9187 loading_request=1 instance=00c61b117cd98158a19907ee622632a98276e80d app_engine_release=1.9.11",
            "205.251.208.42 - - [09/Sep/2014:00:15:00 -0700] \"GET /public/image.jpg HTTP/1.1\" 200 51043 - \"Amazon CloudFront\" \"mydomain.com\" ms=23785 cpu_ms=19390 cpm_usd=0.005704 loading_request=1 pending_ms=8619 instance=00c61b117c0f2baf906ea8bf09e7ea9a6b03ef app_engine_release=1.9.11",
            "0.1.0.30 - - [09/Sep/2014:01:54:34 -0700] \"POST /path/Cgw HTTP/1.1\" 500 51 - \"AppEngine-Google; (+http://code.google.com/appengine; appid: s~appengine-project)\" \"mydomain.com\" ms=59515 cpu_ms=436 cpm_usd=0.000006 exit_code=104 instance=00c61b117c4a26cfc49cbc354e9d6a9d67ebc1 app_engine_release=1.9.11",
            "0.1.0.2 - - [09/Sep/2014:01:54:40 -0700] \"POST /path/4KDA/attach HTTP/1.1\" 400 75 \"http://mydomain.com/path/GCgw\" \"AppEngine-Google; (+http://code.google.com/appengine)\" \"mydomain.com\" ms=213 cpu_ms=28 cpm_usd=0.000008 queue_name=attach-queue task_name=8839398415480343563 instance=00c61b117c3aa499cd827085818bfc840e3727 app_engine_release=1.9.11",
            "78.41.129.246 - - [09/Sep/2014:01:55:19 -0700] \"GET /images/logo.jpg HTTP/1.1\" 304 0 \"http://mydomain.com/File.jsp\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 Safari/537.36\" \"mydomain.com\" ms=57 cpu_ms=0 app_engine_release=1.9.11",
            "0.1.0.2 - - [09/Sep/2014:02:22:45 -0700] \"DELETE /longpath/Eg HTTP/1.1\" 200 28 \"http://mydomain.com/fullpath/goM\" \"AppEngine-Google; (+http://code.google.com/appengine)\" \"sub.domain.com\" ms=1707 cpu_ms=15 cpm_usd=0.000003 queue_name=generic-queue task_name=3249496514792712544 pending_ms=1560 instance=00c61b117cbb772ed6f9b6e7f202aebc350f5223 app_engine_release=1.9.11",
            "0.1.0.30 - - [09/Sep/2014:02:25:25 -0700] \"POST /longPath HTTP/1.1\" 500 51 - \"AppEngine-Google; (+http://code.google.com/appengine; appid: s~google-project)\" \"sub.domain.com\" ms=68486 cpu_ms=20929 cpm_usd=0.000006 loading_request=1 pending_ms=8074 exit_code=104 instance=00c61b117c759fc96edabe2144566bda4cdcd3 app_engine_release=1.9.11",
            "0.1.0.2 - - [09/Sep/2014:02:24:31 -0700] \"DELETE /path/xI HTTP/1.1\" 200 28 \"http://sub.domain.com/path/oM\" \"AppEngine-Google; (+http://code.google.com/appengine)\" \"sub.domain.com\" ms=14625 cpu_ms=14645 cpm_usd=0.000003 queue_name=generic-queue task_name=3249496514792710480 loading_request=1 pending_ms=2438 instance=00c61b117ca64be5bbdec5b392346094c983b1c8 app_engine_release=1.9.11"
            ].each do |message|
                sample message do
                    insist {subject["result"]} == message
                end
            end
        end
        
        # normal request
        sample "54.240.145.210 - - [09/Sep/2014:00:00:00 -0700] \"GET /image.jpeg HTTP/1.1\" 200 14209 - \"Amazon CloudFront\" \"mydomain.com\" ms=202 cpu_ms=103 cpm_usd=0.001588 instance=00c61b117cd582cbba5e6d6c204dd63bb2e930f0 app_engine_release=1.9.11" do
            insist { subject["hostname"] } == "\"mydomain.com\""
            insist { subject["ms"] } == 202
            insist { subject["cpu_ms"] } == 103
            insist { subject["cpm_usd"] } == 0.001588
            insist { subject["instance"] } == "00c61b117cd582cbba5e6d6c204dd63bb2e930f0"
            insist { subject["app_engine_release"] } == "1.9.11"
        end
        
        # request with app engine release 1.9.9
        sample "54.240.145.210 - - [09/Sep/2014:00:00:00 -0700] \"GET /image.jpeg HTTP/1.1\" 200 14209 - \"Amazon CloudFront\" \"mydomain.com\" ms=202 cpu_ms=103 cpm_usd=0.001588 instance=00c61b117cd582cbba5e6d6c204dd63bb2e930f0 app_engine_release=1.9.11" do
            insist { subject["hostname"] } == "\"mydomain.com\""
            insist { subject["ms"] } == 202
            insist { subject["cpu_ms"] } == 103
            insist { subject["cpm_usd"] } == 0.001588
            insist { subject["instance"] } == "00c61b117cd582cbba5e6d6c204dd63bb2e930f0"
            insist { subject["app_engine_release"] } == "1.9.11"
        end
        
        # request with loading_request param
        sample "0.1.0.3 - - [09/Sep/2014:00:06:38 -0700] \"GET /_ah/warmup HTTP/1.1\" 200 0 - - \"fulldomain.appspot.com\" ms=7425 cpu_ms=9187 loading_request=1 instance=00c61b117cd98158a19907ee622632a98276e80d app_engine_release=1.9.11" do
            insist { subject["ms"] } == 7425
            insist { subject["cpu_ms"] } == 9187
            insist { subject["loading_request"] } == 1
            insist { subject["instance"] } == "00c61b117cd98158a19907ee622632a98276e80d"
            insist { subject["app_engine_release"] } == "1.9.11"
        end
        
        # request with pending_ms param
        sample "205.251.208.42 - - [09/Sep/2014:00:15:00 -0700] \"GET /public/image.jpg HTTP/1.1\" 200 51043 - \"Amazon CloudFront\" \"mydomain.com\" ms=23785 cpu_ms=19390 cpm_usd=0.005704 loading_request=1 pending_ms=8619 instance=00c61b117c0f2baf906ea8bf09e7ea9a6b03ef app_engine_release=1.9.11" do
        	insist { subject["hostname"] } == "\"mydomain.com\""
        	insist { subject["ms"] } == 23785
            insist { subject["cpu_ms"] } == 19390
            insist { subject["cpm_usd"] } == 0.005704
            insist { subject["loading_request"] } == 1
            insist { subject["pending_ms"] } == 8619
            insist { subject["instance"] } == "00c61b117c0f2baf906ea8bf09e7ea9a6b03ef"
            insist { subject["app_engine_release"] } == "1.9.11"
        end
        
        # request with exit_code param
        sample "0.1.0.30 - - [09/Sep/2014:01:54:34 -0700] \"POST /path/Cgw HTTP/1.1\" 500 51 - \"AppEngine-Google; (+http://code.google.com/appengine; appid: s~appengine-project)\" \"mydomain.com\" ms=59515 cpu_ms=436 cpm_usd=0.000006 exit_code=104 instance=00c61b117c4a26cfc49cbc354e9d6a9d67ebc1 app_engine_release=1.9.11" do
        	insist { subject["hostname"] } == "\"mydomain.com\""
        	insist { subject["ms"] } == 59515
            insist { subject["cpu_ms"] } == 436
            insist { subject["cpm_usd"] } == 0.000006
            insist { subject["exit_code"] } == 104
            insist { subject["instance"] } == "00c61b117c4a26cfc49cbc354e9d6a9d67ebc1"
            insist { subject["app_engine_release"] } == "1.9.11"
        end
        
        # request with queue_name and task_name params
        sample "0.1.0.2 - - [09/Sep/2014:01:54:40 -0700] \"POST /path/4KDA/attach HTTP/1.1\" 400 75 \"http://mydomain.com/path/GCgw\" \"AppEngine-Google; (+http://code.google.com/appengine)\" \"mydomain.com\" ms=213 cpu_ms=28 cpm_usd=0.000008 queue_name=attach-queue task_name=8839398415480343563 instance=00c61b117c3aa499cd827085818bfc840e3727 app_engine_release=1.9.11" do
        	insist { subject["hostname"] } == "\"mydomain.com\""
        	insist { subject["ms"] } == 213
            insist { subject["cpu_ms"] } == 28
            insist { subject["cpm_usd"] } == 0.000008
            insist { subject["queue_name"] } == "attach-queue"
            insist { subject["task_name"] } == "8839398415480343563"
            insist { subject["instance"] } == "00c61b117c3aa499cd827085818bfc840e3727"
            insist { subject["app_engine_release"] } == "1.9.11"
        end
        
        # request without instance and cpm_usd
        sample "78.41.129.246 - - [09/Sep/2014:01:55:19 -0700] \"GET /images/logo.jpg HTTP/1.1\" 304 0 \"http://mydomain.com/File.jsp\" \"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_9_4) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/37.0.2062.94 Safari/537.36\" \"mydomain.com\" ms=57 cpu_ms=0 app_engine_release=1.9.11" do
        	insist { subject["hostname"] } == "\"mydomain.com\""
        	insist { subject["ms"] } == 57
            insist { subject["cpu_ms"] } == 0
            insist { subject["app_engine_release"] } == "1.9.11"
        end
        
    end
    
end
