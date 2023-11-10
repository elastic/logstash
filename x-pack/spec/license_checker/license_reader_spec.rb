# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require 'support/helpers'
require "license_checker/license_reader"
require "helpers/elasticsearch_options"
require "monitoring/monitoring"
require "logstash/runner"

describe LogStash::LicenseChecker::LicenseReader do
  let(:elasticsearch_url) { "https://localhost:9898" }
  let(:elasticsearch_username) { "elastictest" }
  let(:elasticsearch_password) { "testchangeme" }
  let(:extension) { LogStash::MonitoringExtension.new }
  let(:system_settings) do
    LogStash::Runner::SYSTEM_SETTINGS.clone.tap do |system_settings|
      extension.additionals_settings(system_settings) # register defaults from extension
      apply_settings(settings, system_settings) # apply `settings`
    end
  end
  let(:product_origin_header) { { "x-elastic-product-origin" => "logstash" } }

  let(:settings) do
    {
      "xpack.monitoring.enabled" => true,
      "xpack.monitoring.elasticsearch.hosts" => [elasticsearch_url],
      "xpack.monitoring.elasticsearch.username" => elasticsearch_username,
      "xpack.monitoring.elasticsearch.password" => elasticsearch_password,
    }
  end

  # TODO: fix indirection
  # by the time the LicenseReader is initialized, a Hash of es_options for the feature
  # have already been extracted from the given Settings, and while the Settings required
  # they are not actually used.
  let(:elasticsearch_options) do
    LogStash::Helpers::ElasticsearchOptions.es_options_from_settings('monitoring', system_settings)
  end

  before(:each) do
    # We do _not_ want the client's connection pool to start on initialization, as error conditions
    # from accidentally succeeding at establishing a connection to an HTTP resource that's not actually
    # a live Elasticsearch (e.g., reaped cloud instance) can cause errors.
    allow_any_instance_of(LogStash::Outputs::ElasticSearch::HttpClient::Pool).to receive(:start)
  end

  subject { described_class.new(system_settings, 'monitoring', elasticsearch_options) }

  describe '#fetch_xpack_info' do
    let(:xpack_info_class) { LogStash::LicenseChecker::XPackInfo }
    let(:mock_client) { double('Client') }
    before(:each) { expect(subject).to receive(:client).and_return(mock_client).at_most(:twice) }
    let(:xpack_info) do
      {
          "license" => {},
          "features" => {},
      }
    end

    context 'when client fetches xpack info' do
      before(:each) do
        expect(mock_client).to receive(:get).with('_xpack').and_return(xpack_info)
      end
      it 'returns an XPackInfo' do
        expect(subject.fetch_xpack_info).to eq(xpack_info_class.from_es_response(xpack_info))
      end
    end

    context 'and receives HostUnreachableError' do
      let(:host_not_reachable) { LogStash::Outputs::ElasticSearch::HttpClient::Pool::HostUnreachableError.new(StandardError.new("original error"), "http://localhost:19200") }
      before(:each) do
        # set up expectation of single failure
        expect(subject.logger).to receive(:warn).with(a_string_starting_with("Attempt to validate Elasticsearch license failed."), any_args)
        expect(mock_client).to receive(:get).with('_xpack').and_raise(host_not_reachable).once

        # ensure subsequent success
        expect(mock_client).to receive(:get).with('_xpack').and_return(xpack_info)
      end
      it 'continues to fetch and return an XPackInfo' do
        expect(subject.fetch_xpack_info.failed?).to be false
      end
    end
    context 'when client raises a ConnectionError' do
      before(:each) do
        expect(mock_client).to receive(:get).with('_xpack').and_raise(Puma::ConnectionError)
      end
      it 'returns failed to fetch' do
        expect(subject.fetch_xpack_info.failed?).to be_truthy
      end
    end
    context 'when client raises a 5XX' do
      let(:exception_500) { LogStash::Outputs::ElasticSearch::HttpClient::Pool::BadResponseCodeError.new(500, '', '', '') }
      before(:each) do
        expect(mock_client).to receive(:get).with('_xpack').and_raise(exception_500)
      end
      it 'returns nil' do
        expect(subject.fetch_xpack_info.failed?).to be_truthy
      end
    end
    context 'when client raises a 404' do
      let(:exception_404) do
        LogStash::Outputs::ElasticSearch::HttpClient::Pool::BadResponseCodeError.new(404, '', '', '')
      end
      before(:each) do
        expect(mock_client).to receive(:get).with('_xpack').and_raise(exception_404)
      end
      it 'returns an XPackInfo indicating that X-Pack is not installed' do
        expect(subject.fetch_xpack_info).to eq(xpack_info_class.xpack_not_installed)
      end
    end
    context 'when client returns a 404' do
      # TODO: really, dawg? which is it? exceptions or not?
      let(:body_404) do
        {"status" => 404}
      end
      before(:each) do
        expect(mock_client).to receive(:get).with('_xpack').and_return(body_404)
      end
      it 'returns an XPackInfo indicating that X-Pack is not installed' do
        expect(subject.fetch_xpack_info).to eq(xpack_info_class.xpack_not_installed)
      end
    end
  end

  describe 'fetch_cluster_info' do
    let(:mock_client) { double('Client') }
    before(:each) { expect(subject).to receive(:client).and_return(mock_client).at_most(:twice) }

    context 'when client fetches cluster info' do
      before(:each) do
        expect(mock_client).to receive(:get).with('/').and_return(cluster_info)
      end
      it 'returns cluster info' do
        expect(subject.fetch_cluster_info).to eq(cluster_info)
      end
    end

    context 'and receives HostUnreachableError' do
      let(:host_not_reachable) { LogStash::Outputs::ElasticSearch::HttpClient::Pool::HostUnreachableError.new(StandardError.new("original error"), "http://localhost:19200") }
      before(:each) do
        expect(mock_client).to receive(:get).with('/').and_raise(host_not_reachable).once
        expect(mock_client).to receive(:get).with('/').and_return(cluster_info)
      end
      it 'continues to fetch and return cluster info' do
        expect(subject.fetch_cluster_info).to eq(cluster_info)
      end
    end

    context 'and receives ConnectionError' do
      before(:each) do
        expect(mock_client).to receive(:get).with('/').and_raise(LogStash::Outputs::ElasticSearch::HttpClient::Pool::NoConnectionAvailableError.new)
      end
      it 'returns empty map' do
        expect(subject.fetch_cluster_info).to eq({})
      end
    end

    context 'when client raises a 5XX' do
      let(:exception_500) { LogStash::Outputs::ElasticSearch::HttpClient::Pool::BadResponseCodeError.new(500, '', '', '') }
      before(:each) do
        expect(mock_client).to receive(:get).with('/').and_raise(exception_500)
      end
      it 'returns empty map' do
        expect(subject.fetch_cluster_info).to eq({})
      end
    end
  end

  it "builds ES client" do
    expect(subject.client.options[:hosts].size).to eql 1
    expect(subject.client.options[:hosts][0].to_s).to eql elasticsearch_url # URI#to_s
    expect(subject.client.options).to include(:user => elasticsearch_username, :password => elasticsearch_password)
    expect(subject.client.client_settings[:headers]).to include(product_origin_header)
  end

  context 'with cloud_id' do
    let(:cloud_id) do
      'westeurope-1:d2VzdGV1cm9wZS5henVyZS5lbGFzdGljLWNsb3VkLmNvbTo5MjQzJGUxZTYzMTIwMWZiNjRkNTVhNzVmNDMxZWI2MzQ5NTg5JDljYzYwMGUwMGQwYjRhMThiNmY2NmU2ZTcyMTQwODA3'
    end
    let(:cloud_auth) do
      'elastic:LnWMLeK3EQPTf3G3F1IBdFvO'
    end

    let(:settings) do
      {
          "xpack.monitoring.enabled" => true,
          "xpack.monitoring.elasticsearch.cloud_id" => cloud_id,
          "xpack.monitoring.elasticsearch.cloud_auth" => cloud_auth
      }
    end

    it "builds ES client" do
      expect(subject.client.options[:hosts].size).to eql 1
      expect(subject.client.options[:hosts][0].to_s).to eql 'https://e1e631201fb64d55a75f431eb6349589.westeurope.azure.elastic-cloud.com:9243'
      expect(subject.client.options).to include(:user => 'elastic', :password => 'LnWMLeK3EQPTf3G3F1IBdFvO')
      expect(subject.client.client_settings[:headers]).to include(product_origin_header)
    end
  end

  context 'with api_key' do
    let(:api_key) { "foo:bar" }
    let(:settings) do
      {
        "xpack.monitoring.enabled" => true,
        "xpack.monitoring.elasticsearch.hosts" => [elasticsearch_url],
        "xpack.monitoring.elasticsearch.api_key" => api_key,
      }
    end

    it "builds ES client" do
      expect(subject.client.client_settings[:headers]).to include("Authorization" => "ApiKey Zm9vOmJhcg==")
      expect(subject.client.client_settings[:headers]).to include(product_origin_header)
    end
  end
end
