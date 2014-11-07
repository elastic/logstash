# encoding: utf-8

require File.join(File.dirname(__FILE__), 'fixtures.rb')
require "logstash/codecs/netflow"
require "logstash/event"
require "insist"
require "pry"
require "pry-rescue"

describe LogStash::Codecs::Netflow do
  context "#decode NetFlow v9" do
    let(:message) {
      netflow_v9_header(:record_count => 2) +
      netflow_v9_template_flowset_simple +
      netflow_v9_data_flowset_simple(:record_count => 1)
    }

    it "should respect the 'target' setting" do
      default_codec    = LogStash::Codecs::Netflow.new
      configured_codec = LogStash::Codecs::Netflow.new("target" => "testing")
      default_codec.decode(message) do |event|
        insist { event["netflow"]["flow_seq_num"] } == 48879
      end
      configured_codec.decode(message) do |event|
        insist { event["netflow"] }.nil?
        insist { event["testing"]["flow_seq_num"] } == 48879
      end
    end

    context "with a single Data Record and no matching Template" do
      let(:message) {
        netflow_v9_header(:record_count => 1) +
        netflow_v9_data_flowset_simple(:record_count => 1)
      }
      it "should not return an event" do
        events = Array.new
        subject.decode(message) do |event|
          events << event        
        end
        insist { events.length } == 0
      end
    end

    context "with a single simple Data Record after a matching Template" do
      let(:message) {
        netflow_v9_header(:record_count => 2) +
        netflow_v9_template_flowset_simple +
        netflow_v9_data_flowset_simple(:record_count => 1)
      }
      it "should return a valid event" do
        events = Array.new
        subject.decode(message) do |event|
          events << event        
        end
        insist { events.length } == 1
        events.each do |event|
          insist { event.is_a? LogStash::Event }
          # TODO: See why current implementation trucates milliseconds
          timestamp = Time.iso8601("2014-04-04T01:24:01.000Z")
          insist { event["@timestamp"]               } == timestamp
          insist { event["netflow"]["version"]       } == 9
          insist { event["netflow"]["flow_seq_num"]  } == 48879
          insist { event["netflow"]["flowset_id"]    } == 321
          insist { event["netflow"]["in_bytes"]      } == 128000
          insist { event["netflow"]["in_pkts"]       } == 1024
          insist { event["netflow"]["protocol"]      } == 17
          insist { event["netflow"]["l4_src_port"]   } == 12345
          insist { event["netflow"]["ipv4_src_addr"] } == "10.1.2.3"
          insist { event["netflow"]["l4_dst_port"]   } == 5559
          insist { event["netflow"]["ipv4_dst_addr"] } == "10.4.5.6"
        end
      end
    end

    context "with a single complex Data Record after a matching Template" do
      let(:message) {
        netflow_v9_header(:record_count => 2) +
        netflow_v9_template_flowset_complex +
        netflow_v9_data_flowset_complex
      }
      it "should return a valid event" do
require 'pry'
binding.pry
        events = Array.new
        subject.decode(message) do |event|
          events << event        
        end
        insist { events.length } == 1
        events.each do |event|
          insist { event.is_a? LogStash::Event }
          insist { event["netflow"]["tcp_flags"] } == 0x13
          insist { event["netflow"]["input_snmp"] } == 1
          insist { event["netflow"]["output_snmp"] } == 2
          insist { event["netflow"]["last_switched"] } == 0
          insist { event["netflow"]["first_switched"] } == 0
          insist { event["netflow"]["if_name"] } == "FE1/0"
          insist { event["netflow"]["if_desc"] } == "FastEthernet 1/0"
          insist { event["netflow"]["forwarding_status"] } == 0x42
        end
      end
    end

    context "with multiple Data Records after a matching Template" do
      let(:message) {
        netflow_v9_header(:record_count => 5) +
        netflow_v9_template_flowset_simple +
        netflow_v9_data_flowset_simple(:record_count => 4)
      }

      it "should return multiple valid events" do
        events = Array.new
        subject.decode(message) do |event|
          events << event        
        end
        insist { events.length } == 4
        events.each do |event|
          insist { event.is_a? LogStash::Event }
          # TODO: See why current implementation trucates milliseconds
          timestamp = Time.iso8601("2014-04-04T01:24:01.000Z")
          insist { event["@timestamp"]               } == timestamp
          insist { event["netflow"]["version"]       } == 9
          insist { event["netflow"]["flow_seq_num"]  } == 48879
          insist { event["netflow"]["flowset_id"]    } == 321
        end
      end
    end

    context "with matching and non-matching Data Records around a Template" do
      let(:message) {
        netflow_v9_header(:record_count => 5) +
        netflow_v9_data_flowset_simple +
        netflow_v9_data_flowset_complex +
        netflow_v9_template_flowset_simple +
        netflow_v9_data_flowset_simple +
        netflow_v9_data_flowset_complex
      }

      it "should return only the event from after the matching Template" do
        events = Array.new
        subject.decode(message) do |event|
          events << event        
        end
        insist { events.length } == 1
        events.each do |event|
          insist { event["netflow"]["in_pkts"] } == 1024
        end
      end
    end

  end
end
