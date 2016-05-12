# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "logstash/api/modules/node"
require "logstash/json"

describe LogStash::Api::Modules::Node do

  include Rack::Test::Methods

  def app()
    described_class
  end

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
        expect(payload["threads"].count).to be <= 5
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

  end
end
