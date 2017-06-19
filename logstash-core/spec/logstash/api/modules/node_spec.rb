# encoding: utf-8
require "spec_helper"
require "json-schema"
require "sinatra"
require "logstash/api/modules/node"

describe LogStash::Api::Modules::Node do
  include_context "api setup"
  include_examples "not found"

  describe "#hot threads" do

    before(:all) do
      get "/hot_threads"
    end

    it "respond OK" do
      expect(last_response).to be_ok
    end

    it "should return a JSON object" do
      expect(JSON::Validator.validate({}, last_response.body)).to eq(true)
    end

    context "#threads count" do

      before(:all) do
        get "/hot_threads?threads=5"
      end

      it "should return a json payload content type" do
        expect(last_response.content_type).to eq("application/json")
      end

      it "should return information for <= # requested threads" do
        expect(JSON::Validator.fully_validate(
          {
            "properties" => {
              "hot_threads" => {
                "properties" => { "threads" => { "type" => "array", "maxItems" => 5 } }
              }
            }
          },
          last_response.body
        )).to be_empty
      end
    end

    context "when asking for human output" do
      [
        "/hot_threads?human",
        "/hot_threads?human=true",
        "/hot_threads?human=1",
        "/hot_threads?human=t",
      ].each do |path|

        before(:all) do
          get path
        end

        it "should return a text/plain content type" do
          expect(last_response.content_type).to eq("text/plain;charset=utf-8")
        end

        it "should return a plain text payload" do
          expect {JSON::Validator.fully_validate({}, payload)}.to raise_error
        end
      end
    end

    context "When asking for human output and threads count" do
      before(:all) do
        # Make sure we have enough threads for this to work.
        @threads = []
        5.times { @threads << Thread.new { loop {} } }

        get "/hot_threads?human=t&threads=2"
      end

      after(:all) do
        @threads.each { |t| t.kill } rescue nil
      end

      it "should return information for <= # requested threads" do
        expect(last_response.body.scan(/thread name/).size).to eq(2)
      end
    end

    context "when not asking for human output" do
      [
        "/hot_threads?human=false",
        "/hot_threads?human=0",
        "/hot_threads?human=f",
      ].each do |path|
        before(:all) do
          get path
        end

        it "should return a json payload content type" do
          expect(last_response.content_type).to eq("application/json")
        end

        it "should return a json payload" do
          expect(JSON::Validator.validate({}, last_response.body)).to eq(true)
        end
      end
    end

    describe "Generic JSON testing" do
      extend ResourceDSLMethods

      root_structure = {
        "pipelines" => {
          "main" => {
            "workers" => Numeric,
            "batch_size" => Numeric,
            "batch_delay" => Numeric,
            "config_reload_automatic" => Boolean,
            "config_reload_interval" => Numeric,
            "dead_letter_queue_enabled" => Boolean
          }
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
        },
        "gc_collectors" => Array
        },
        "hot_threads"=> {
          "time" => String,
          "busiest_threads" => Numeric,
          "threads" => Array
        }
      }

      test_api_and_resources(root_structure, :exclude_from_root => ["hot_threads"])
    end
  end
end
