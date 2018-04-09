# encoding: utf-8
require "spec_helper"
require "logstash/modules/kibana_client"
module LogStash module Modules
  KibanaTestResponse = Struct.new(:code, :body, :headers)
  class KibanaTestClient
    def http(method, endpoint, options)
      self
    end
    def call
      KibanaTestResponse.new(200, '{"version":{"number":"1.2.3","build_snapshot":false}}', {})
    end
  end
  describe KibanaClient do
    let(:settings) { Hash.new }
    let(:test_client) { KibanaTestClient.new }
    let(:kibana_host) { "https://foo.bar:4321" }
    subject(:kibana_client) { described_class.new(settings, test_client) }

    context "when supplied with conflicting scheme data" do
      let(:settings) { {"var.kibana.scheme" => "http", "var.kibana.host" => kibana_host} }
      it "a new instance will throw an error" do
        expect{described_class.new(settings, test_client)}.to raise_error(ArgumentError, /Detected differing Kibana host schemes as sourced from var\.kibana\.host: 'https' and var\.kibana\.scheme: 'http'/)
      end
    end

    context "when supplied with invalid schemes" do
      ["httpd", "ftp", "telnet"].each do |uri_scheme|
        it "a new instance will throw an error" do
          re = /Kibana host scheme given is invalid, given value: '#{uri_scheme}' - acceptable values: 'http', 'https'/
          expect{described_class.new({"var.kibana.scheme" => uri_scheme}, test_client)}.to raise_error(ArgumentError, re)
        end
      end
    end

    context "when supplied with the scheme in the host only" do
      let(:settings) { {"var.kibana.host" => kibana_host} }
      it "has a version and an endpoint" do
        expect(kibana_client.version).to eq("1.2.3")
        expect(kibana_client.endpoint).to eq("https://foo.bar:4321")
      end
    end

    context "when supplied with the scheme in the scheme setting" do
      let(:settings) { {"var.kibana.scheme" => "https", "var.kibana.host" => "foo.bar:4321"} }
      it "has a version and an endpoint" do
        expect(kibana_client.version).to eq("1.2.3")
        expect(kibana_client.endpoint).to eq(kibana_host)
      end
    end

    context "when supplied with a no scheme host setting and ssl is enabled" do
      let(:settings) { {"var.kibana.ssl.enabled" => "true", "var.kibana.host" => "foo.bar:4321"} }
      it "has a version and an endpoint" do
        expect(kibana_client.version).to eq("1.2.3")
        expect(kibana_client.endpoint).to eq(kibana_host)
      end
    end

    describe "ssl option handling" do
      context "when using a string for ssl.enabled" do
        let(:settings) do
          { "var.kibana.ssl.enabled" => "true" }
        end

        it "should set the ssl options" do
          expect(Manticore::Client).to receive(:new) do |args|
            expect(args[:ssl]).to_not be_empty
          end.and_return(test_client)
          described_class.new(settings)
        end
      end

      context "when using a boolean for ssl.enabled" do
        let(:settings) do
          { "var.kibana.ssl.enabled" => true }
        end

        it "should set the ssl options" do
          expect(Manticore::Client).to receive(:new) do |args|
            expect(args[:ssl]).to_not be_empty
          end.and_return(test_client)
          described_class.new(settings)
        end
      end
    end
  end
end end
