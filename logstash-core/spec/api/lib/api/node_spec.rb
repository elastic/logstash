# encoding: utf-8
require_relative "../../spec_helper"
require "sinatra"
require "app/modules/node"

describe LogStash::Api::Node do

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
      expect{ JSON.parse(last_response.body) }.not_to raise_error
    end

    context "#threads count" do

      before(:all) do
        do_request { get "/hot_threads?threads=5" }
      end

      let(:payload) { JSON.parse(last_response.body) }

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

    context "when requesting idle threads" do

      before(:all) do
        do_request { get "/hot_threads?ignore_idle_threads=false&threads=10" }
      end

      let(:payload) { JSON.parse(last_response.body) }

      it "should return JIT threads" do
        thread_names = payload["threads"].map { |thread_info| thread_info["name"] }
        expect(thread_names.grep(/JIT/)).not_to be_empty
      end
    end

  end
end
