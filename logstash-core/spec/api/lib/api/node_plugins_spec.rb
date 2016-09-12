# encoding: utf-8
require_relative "../../../support/shared_examples"
require_relative "../../spec_helper"
require "sinatra"
require "logstash/api/modules/plugins"
require "logstash/json"

describe LogStash::Api::Modules::Plugins do
  include_context "api setup"
  include_examples "not found"

  extend ResourceDSLMethods

  before(:each) do
    do_request { get "/" }
  end

  let(:payload) { LogStash::Json.load(last_response.body) }

  describe "retrieving plugins" do
    it "should return OK" do
      expect(last_response).to be_ok
    end

    it "should return a list of plugins" do
      expect(payload["plugins"]).to be_a(Array)
    end

    it "should return the total number of plugins" do
      expect(payload["total"]).to be_a(Numeric)
    end
  end
end
