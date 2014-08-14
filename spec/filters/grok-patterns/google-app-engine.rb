# encoding: utf-8
require "test_utils"

# Test suite for the grok patterns defined in patterns/google-app-engine
# For each pattern:
#  - a sample is considered valid i.e. "should match"  where message == result
#  - a sample is considered invalid i.e. "should NOT match"  where message != result
#
describe "google app engine grok pattern" do
    extend LogStash::RSpec
    
    describe "GAELOG" do
        config <<-CONFIG
        filter {
            grok {
                match => { "message" => "%{GAELOG:result}" }
            }
        }
        CONFIG
        
        context "should match" do
            [
            "0.1.0.1 - - [11/Aug/2014:05:00:00 -0700] \"GET /first/path HTTP/1.1\" 200 44 - \"AppEngine-Google; (+http://code.google.com/appengine)\"",
            "0.1.0.2 - - [11/Aug/2014:05:00:00 -0700] \"POST /another/path HTTP/1.1\" 204 0 \"http://mydomain.com/referrer\" \"AppEngine-Google; (+http://code.google.com/appengine)\""
            ].each do |message|
                sample message do
                    insist {subject["result"]} == message
                end
            end
        end
        context "should NOT match" do
            [
            "205.251.208.18 - - [11/Aug/2014:00:00:07 -0700] \"GET /main/path HTTP/1.1\" 200 19896 - \"Referrer String\" \"mydomain.com\" ms=59 cpu_ms=62 cpm_usd=0.002224 instance=00c61b117c8717096ff64563cf71f30641cf995d app_engine_release=1.9.8 trace_id=649a71703f21791d12e87f46f8c83dcd",
            ].each do |message|
                sample message do
                    insist {subject["result"]} != message
                end
            end
        end
        
        sample "0.1.0.2 - - [11/Aug/2014:05:00:00 -0700] \"POST /another/path HTTP/1.1\" 204 0 \"http://mydomain.com/referrer\" \"AppEngine-Google; (+http://code.google.com/appengine)\"" do
            insist { subject["referrer"] } == "\"http://mydomain.com/referrer\""
            insist { subject["agent"] } == "\"AppEngine-Google; (+http://code.google.com/appengine)\""
        end
    end
    
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
            "205.251.208.18 - - [11/Aug/2014:00:00:07 -0700] \"GET /main/path HTTP/1.1\" 200 19896 - \"Referrer String\" \"mydomain.com\" ms=59 cpu_ms=62 cpm_usd=0.002224 instance=00c61b117c8717096ff64563cf71f30641cf995d app_engine_release=1.9.8 trace_id=649a71703f21791d12e87f46f8c83dcd",
            "0.1.0.3 - - [11/Aug/2014:11:56:38 -0700] \"GET /_ah/warmup HTTP/1.1\" 200 0 - - \"mydomain.com\" ms=15192 cpu_ms=19147 loading_request=1 instance=00c61b117cca2457cdf71e7f6187ac76aa90590c app_engine_release=1.9.8 trace_id=0cb6fce856b4451a28e06194a42d59fe",
            "205.251.208.42 - - [11/Aug/2014:12:52:03 -0700] \"GET /image.jpg HTTP/1.1\" 200 62795 - \"Referrer String\" \"mydomain.com\" ms=24877 cpu_ms=17999 cpm_usd=0.007018 loading_request=1 pending_ms=10572 instance=00c61b117c58c56f7d2d90ee67d4a01e43e262 app_engine_release=1.9.8 trace_id=cd59e954c8a3d2142bcfef9f923839bf",
            "205.251.208.18 - - [11/Aug/2014:12:51:55 -0700] \"GET /public/files/ahJzfm1hcDJhcHAtcGxhdGZvcm1yLAsSC1VzZXJBY2NvdW50GK2iDAwLEgVBbGJ1bRi6FwwLEgVNZWRpYRirgQoM_ORIGINAL=s640.jpg HTTP/1.1\" 200 77961 - \"Referrer String\" \"mydomain.com\" ms=16993 cpu_ms=18395 cpm_usd=0.008713 loading_request=1 instance=00c61b117c895aad5344960bc5673b2f8652d7 app_engine_release=1.9.8 trace_id=160462e198259582cd987016057a05ce",
            "216.137.62.18 - - [11/Aug/2014:12:37:50 -0700] \"GET /animage.jpg HTTP/1.1\" 200 22029 - \"Referrer String\" \"mydomain.com\" ms=16749 cpu_ms=17187 cpm_usd=0.002462 loading_request=1 instance=00c61b117c74a08ddd0eb033a807fdbff928ad app_engine_release=1.9.8 trace_id=3b9e760a3255e7500f348275276e4206",
            "79.38.174.111 - - [12/Aug/2014:00:00:48 -0700] \"GET /vthumb_grip.png HTTP/1.1\" 200 0 \"http://mydomain.com/file.jsp\" \"Mozilla/5.0 (Windows NT 6.0) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/36.0.1985.125 Safari/537.36\" \"mydomain.com\" ms=57 cpu_ms=0 app_engine_release=1.9.9 trace_id=85b1c3e86fc703ecdad61b7f85456d40",
            "0.1.0.2 - - [13/Aug/2014:08:29:16 -0700] \"POST /testpath HTTP/1.1\" 202 67 \"http://mydomain/endpoint\"; \"AppEngine-Google; (+http://code.google.com/appengine)\" \"mydomain.com\" ms=45787 cpu_ms=27188 cpm_usd=0.071525 queue_name=name-queue task_name=13646048306045697056 instance=00c61b117c6b9e63d18bfa55a4be5369794b2b64 app_engine_release=1.9.9 trace_id=a1f770a9c5a2e6ad23de2c0222473c81",
            "205.251.208.42 - - [10/Aug/2014:09:50:05 -0700] \"GET /test.jpg HTTP/1.1\" 500 0 - \"Referrer String\" \"mydomain.com\" ms=1722 cpu_ms=0 exit_code=203 instance=00c61b117c47f541c61562bb9a466d2647c3db app_engine_release=1.9.8 trace_id=cb208a3496eb90039b3342682de8fa40",
            "0.1.0.2 - - [13/Aug/2014:08:04:28 -0700] \"POST /long/path/request HTTP/1.1\" 201 57 \"http://mydomain.com/publishRequests\"; \"AppEngine-Google; (+http://code.google.com/appengine)\" \"cms.map2app.com\" ms=25105 cpu_ms=11144 cpm_usd=0.002562 queue_name=email-queue task_name=2044304020980273760 loading_request=1 pending_ms=4159 instance=00c61b117c1ed91b38fb304b463b0269134b58 app_engine_release=1.9.9 trace_id=029e3cb8e904f69e0ea1e34f14ddc113"
            ].each do |message|
                sample message do
                    insist {subject["result"]} == message
                end
            end
        end
        
        sample "205.251.208.18 - - [11/Aug/2014:00:00:07 -0700] \"GET /main/path HTTP/1.1\" 200 19896 - \"Referrer String\" \"mydomain.com\" ms=59 cpu_ms=62 cpm_usd=0.002224 instance=00c61b117c8717096ff64563cf71f30641cf995d app_engine_release=1.9.8 trace_id=649a71703f21791d12e87f46f8c83dcd" do
            insist { subject["hostname"] } == "\"mydomain.com\""
            insist { subject["ms"] } == 59
            insist { subject["cpu_ms"] } == 62
            insist { subject["cpm_usd"] } == 0.002224
            insist { subject["instance"] } == "00c61b117c8717096ff64563cf71f30641cf995d"
            insist { subject["app_engine_release"] } == "1.9.8"
            insist { subject["trace_id"] } == "649a71703f21791d12e87f46f8c83dcd"
        end
        
        sample "205.251.208.42 - - [11/Aug/2014:12:52:03 -0700] \"GET /image.jpg HTTP/1.1\" 200 62795 - \"Referrer String\" \"mydomain.com\" ms=24877 cpu_ms=17999 cpm_usd=0.007018 loading_request=1 pending_ms=10572 instance=00c61b117c58c56f7d2d90ee67d4a01e43e262 app_engine_release=1.9.8 trace_id=cd59e954c8a3d2142bcfef9f923839bf" do
            insist { subject["hostname"] } == "\"mydomain.com\""
            insist { subject["ms"] } == 24877
            insist { subject["cpu_ms"] } == 17999
            insist { subject["cpm_usd"] } == 0.007018
            insist { subject["loading_request"] } == 1
            insist { subject["pending_ms"] } == 10572
            insist { subject["instance"] } == "00c61b117c58c56f7d2d90ee67d4a01e43e262"
            insist { subject["app_engine_release"] } == "1.9.8"
            insist { subject["trace_id"] } == "cd59e954c8a3d2142bcfef9f923839bf"
        end
    end
    
end
