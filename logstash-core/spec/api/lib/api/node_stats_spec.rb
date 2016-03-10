# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/modules/node_stats"

describe LogStash::Api::NodeStats do

  include Rack::Test::Methods

  def app()
    described_class
  end

  let(:payload) { JSON.parse(last_response.body) }

  context "#root" do

    before(:all) do
      do_request { get "/" }
    end

    it "respond OK" do
      expect(last_response).to be_ok
    end

    ["events", "jvm"].each do |key|
      it "contains #{key} information" do
        expect(payload).to include(key)
      end
    end
  end

  context "#events" do

    let(:payload) { JSON.parse(last_response.body) }

    before(:all) do
      do_request { get "/events" }
    end

    it "respond OK" do
      expect(last_response).to be_ok
    end

    it "contains events information" do
      expect(payload).to include("events")
    end
  end

  context "#jvm" do

    let(:payload) { JSON.parse(last_response.body) }

    before(:all) do
      do_request { get "/jvm" }
    end

    it "respond OK" do
      expect(last_response).to be_ok
    end

    it "contains memory information" do
      expect(payload).to include("mem")
    end
  end

end
