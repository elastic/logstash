# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "logstash/api/modules/node"
require "logstash/json"

describe LogStash::Api::Modules::Node do
  include_context "api setup"

  describe "#hot threads" do

    before(:all) do
      do_request { get "/hot_threads" }
    end

    it "respond OK" do
      expect(last_response).to be_ok
    end

    it "should return a JSON object" do
      expect{ LogStash::Json.load(last_response.body) }.not_to raise_error
    end

    context "#threads count" do

      before(:all) do
        do_request { get "/hot_threads?threads=5" }
      end

      let(:payload) { LogStash::Json.load(last_response.body) }

      it "should return a json payload content type" do
        expect(last_response.content_type).to eq("application/json")
      end

      it "should return information for <= # requested threads" do
        expect(payload["hot_threads"]["threads"].count).to be <= 5
      end
    end

    context "when asking for human output" do

      before(:all) do
        do_request { get "/hot_threads?human" }
      end

      let(:payload) { last_response.body }

      it "should return a text/plain content type" do
        expect(last_response.content_type).to eq("text/plain;charset=utf-8")
      end

      it "should return a plain text payload" do
        expect{ JSON.parse(payload) }.to raise_error
      end
    end

    describe "Generic JSON testing" do
      extend ResourceDSLMethods
      
      root_structure = {
        "pipeline" => {
          "workers" => Numeric,
          "batch_size" => Numeric,
          "batch_delay" => Numeric
        },
        "os" => {
          "name" => String,
          "arch" => String,
          "version" => String,
          "available_processors" => Numeric
        },
        "jvm" => {
          "pid" => Numeric,
          "version" => String,
          "vm_name" => String,
          "vm_version" => String,
          "vm_vendor" => String,
          "start_time_in_millis" => Numeric,
          "mem" => {
            "heap_init_in_bytes" => Numeric,
            "heap_max_in_bytes" => Numeric,
            "non_heap_init_in_bytes" => Numeric,
            "non_heap_max_in_bytes" => Numeric
          }
        },
        "hot_threads"=> {
          "hostname" => String,
          "time" => String,
          "busiest_threads" => Numeric,
          "threads" => Array
        }
      }
      
      test_api_and_resources(root_structure)
    end   
  end
end
