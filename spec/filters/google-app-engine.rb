# encoding: utf-8
require "test_utils"

# Test suite for the grok patterns defined in patterns/google-app-engine
# For each pattern:
#  - a sample is considered valid i.e. "should match"  where message == result
#  - a sample is considered invalid i.e. "should NOT match"  where message != result
#
describe "google app engine grok pattern" do
    extend LogStash::RSpec
    
    describe "GOOGLEAPPENGINELOG" do
        config <<-CONFIG
        filter {
            grok {
                match => { "message" => "%{GOOGLEAPPENGINELOG:result}" }
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
            "205.251.208.18 - - [11/Aug/2014:00:00:07 -0700] \"GET /main/path HTTP/1.1\" 200 19896 - \"Amazon CloudFront\" \"mydomain.com\" ms=59 cpu_ms=62 cpm_usd=0.002224 instance=00c61b117c8717096ff64563cf71f30641cf995d app_engine_release=1.9.8 trace_id=649a71703f21791d12e87f46f8c83dcd",
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
    
    describe "GOOGLEAPPENGINEFULLLOG" do
        config <<-CONFIG
        filter {
            grok {
                match => { "message" => "%{GOOGLEAPPENGINEFULLLOG:result}" }
            }
        }
        CONFIG
        
        context "should match" do
            [
            "205.251.208.18 - - [11/Aug/2014:00:00:07 -0700] \"GET /main/path HTTP/1.1\" 200 19896 - \"Amazon CloudFront\" \"mydomain.com\" ms=59 cpu_ms=62 cpm_usd=0.002224 instance=00c61b117c8717096ff64563cf71f30641cf995d app_engine_release=1.9.8 trace_id=649a71703f21791d12e87f46f8c83dcd"
            ].each do |message|
                sample message do
                    insist {subject["result"]} == message
                end
            end
        end
        
        sample "205.251.208.18 - - [11/Aug/2014:00:00:07 -0700] \"GET /main/path HTTP/1.1\" 200 19896 - \"Amazon CloudFront\" \"mydomain.com\" ms=59 cpu_ms=62 cpm_usd=0.002224 instance=00c61b117c8717096ff64563cf71f30641cf995d app_engine_release=1.9.8 trace_id=649a71703f21791d12e87f46f8c83dcd" do
            insist { subject["hostname"] } == "\"mydomain.com\""
            insist { subject["ms"] } == "59"
            insist { subject["cpu_ms"] } == "62"
            insist { subject["cpm_usd"] } == "0.002224"
            insist { subject["instance"] } == "00c61b117c8717096ff64563cf71f30641cf995d"
            insist { subject["app_engine_release"] } == "1.9.8"
            insist { subject["trace_id"] } == "649a71703f21791d12e87f46f8c83dcd"
        end
    end
    
end
