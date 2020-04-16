# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require 'support/helpers'
require "license_checker/license_reader"
require "helpers/elasticsearch_options"
require "monitoring/monitoring"

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

  let(:settings) do
    {
      "xpack.monitoring.enabled" => true,
      "xpack.monitoring.elasticsearch.hosts" => [ elasticsearch_url ],
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

  subject { described_class.new(system_settings, 'monitoring', elasticsearch_options) }

  describe '#fetch_xpack_info' do
    let(:xpack_info_class) { LogStash::LicenseChecker::XPackInfo }
    let(:mock_client) { double('Client') }
    before(:each) { expect(subject).to receive(:client).and_return(mock_client) }

    context 'when client fetches xpack info' do
      let(:xpack_info) do
        {
            "license" => {},
            "features" => {},
        }
      end
      before(:each) do
        expect(mock_client).to receive(:get).with('_xpack').and_return(xpack_info)
      end
      it 'returns an XPackInfo' do
        expect(subject.fetch_xpack_info).to eq(xpack_info_class.from_es_response(xpack_info))
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
      let(:exception_404)do
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

  it "builds ES client" do
    expect( subject.client.options[:hosts].size ).to eql 1
    expect( subject.client.options[:hosts][0].to_s ).to eql elasticsearch_url # URI#to_s
    expect( subject.client.options ).to include(:user => elasticsearch_username, :password => elasticsearch_password)
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
      expect( subject.client.options[:hosts].size ).to eql 1
      expect( subject.client.options[:hosts][0].to_s ).to eql 'https://e1e631201fb64d55a75f431eb6349589.westeurope.azure.elastic-cloud.com:9243'
      expect( subject.client.options ).to include(:user => 'elastic', :password => 'LnWMLeK3EQPTf3G3F1IBdFvO')
    end
  end
end
