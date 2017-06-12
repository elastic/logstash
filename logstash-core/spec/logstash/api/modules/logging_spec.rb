# encoding: utf-8
require "spec_helper"
require "json-schema"
require "sinatra"
require "logstash/api/modules/logging"

describe LogStash::Api::Modules::Logging do
  include_context "api setup"

  describe "#logging" do

    context "when setting a logger's log level" do
      it "should return a positive acknowledgement on success" do
        put '/', '{"logger.logstash": "ERROR"}'
        expect(JSON::Validator.fully_validate(
          { "properties" => { "acknowledged" => { "enum" => [true] } } },
          last_response.body)
        ).to be_empty
      end

      it "should throw error when level is invalid" do
        put '/', '{"logger.logstash": "invalid"}'
        expect(JSON::Validator.fully_validate(
          { "properties" => { "error" => { "enum" => ["invalid level[invalid] for logger[logstash]"] } } },
          last_response.body)
        ).to be_empty
      end

      it "should throw error when key logger is invalid" do
        put '/', '{"invalid" : "ERROR"}'
        expect(JSON::Validator.fully_validate(
          { "properties" => { "error" => { "enum" => ["unrecognized option [invalid]"] } } },
          last_response.body)
        ).to be_empty
      end
    end
  end
end
