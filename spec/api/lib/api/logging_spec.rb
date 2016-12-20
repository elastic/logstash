# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "logstash/api/modules/logging"
require "logstash/json"

describe LogStash::Api::Modules::Logging do
  include_context "api setup"

  describe "#logging" do

    context "when setting a logger's log level" do
      before(:all) do
        @runner = LogStashRunner.new
        @runner.start
      end

      after(:all) do
        @runner.stop
      end

      it "should return a positive acknowledgement on success" do
        put '/', '{"logger.logstash": "ERROR"}'
        payload = LogStash::Json.load(last_response.body)
        expect(payload['acknowledged']).to eq(true)
      end

      it "should throw error when level is invalid" do
        put '/', '{"logger.logstash": "invalid"}'
        payload = LogStash::Json.load(last_response.body)
        expect(payload['error']).to eq("invalid level[invalid] for logger[logstash]")
      end

      it "should throw error when key logger is invalid" do
        put '/', '{"invalid" : "ERROR"}'
        payload = LogStash::Json.load(last_response.body)
        expect(payload['error']).to eq("unrecognized option [invalid]")
      end
    end
  end
end
