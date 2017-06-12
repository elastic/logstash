# encoding: utf-8
require "spec_helper"
require "json-schema"
require "sinatra"
require "logstash/api/modules/plugins"

describe LogStash::Api::Modules::Plugins do
  include_context "api setup"
  include_examples "not found"

  extend ResourceDSLMethods

  before(:each) do
    get "/"
  end

  describe "retrieving plugins" do
    it "should return OK" do
      expect(last_response).to be_ok
    end

    it "should return a list of plugins" do
      expect(JSON::Validator.fully_validate(
        {
          "properties" => {
            "plugins" => {
              "type" => "array"
            },
            "required" => ["plugins"]
          }
        },
        last_response.body)
      ).to be_empty
    end

    it "should return the total number of plugins" do
      expect(JSON::Validator.fully_validate(
        {
          "properties" => {
            "total" => {
              "type" => "number"
            },
            "required" => ["total"]
          }
        },
        last_response.body)
      ).to be_empty
    end
  end
end
