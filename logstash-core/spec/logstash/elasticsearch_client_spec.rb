# encoding: utf-8
#
require "logstash/elasticsearch_client"

describe LogStash::ElasticsearchClient do
  describe LogStash::ElasticsearchClient::RubyClient do
    let(:settings) { {} }
    let(:logger) { nil }

    describe "ssl option handling" do
      context "when using a string for ssl.enabled" do
        let(:settings) do
          { "var.elasticsearch.ssl.enabled" => "true" }
        end

        it "should set the ssl options" do
          expect(Elasticsearch::Client).to receive(:new) do |args|
            expect(args[:ssl]).to_not be_empty
          end
          described_class.new(settings, logger)
        end
      end

      context "when using a boolean for ssl.enabled" do
        let(:settings) do
          { "var.elasticsearch.ssl.enabled" => true }
        end

        it "should set the ssl options" do
          expect(Elasticsearch::Client).to receive(:new) do |args|
            expect(args[:ssl]).to_not be_empty
          end
          described_class.new(settings, logger)
        end
      end
    end
  end
end
