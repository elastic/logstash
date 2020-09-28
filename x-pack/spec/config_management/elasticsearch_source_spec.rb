# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/json"
require "logstash/runner"
require "config_management/elasticsearch_source"
require "config_management/extension"
require "license_checker/license_manager"
require "monitoring/monitoring"
require "stud/temporary"

describe LogStash::ConfigManagement::ElasticsearchSource do
  let(:elasticsearch_url) { ["https://localhost:9898"] }
  let(:elasticsearch_username) { "elastictest" }
  let(:elasticsearch_password) { "testchangeme" }
  let(:extension) { LogStash::ConfigManagement::Extension.new }
  let(:system_settings) { LogStash::Runner::SYSTEM_SETTINGS.clone }
  let(:mock_license_client)  { double("http_client") }
  let(:license_status) { 'active'}
  let(:license_type) { 'trial' }
  let(:license_expiry_date) { Time.now + (60 * 60 * 24)}
  let(:license_expiry_in_millis) { license_expiry_date.to_i * 1000 }
  let(:license_reader) { LogStash::LicenseChecker::LicenseReader.new(system_settings, 'management') }
  let(:license_response) {
"{
  \"license\": {
    \"status\": \"#{license_status}\",
    \"uid\": \"9a48c67c-ce2c-4169-97bf-37d324b8ab80\",
    \"type\": \"#{license_type}\",
    \"issue_date\": \"2017-07-11T01:35:23.584Z\",
    \"issue_date_in_millis\": 1499736923584,
    \"expiry_date\": \"#{license_expiry_date.to_s}\",
    \"expiry_date_in_millis\": #{license_expiry_in_millis},
    \"max_nodes\": 1000,
    \"issued_to\": \"x-pack-elasticsearch_plugin_run\",
    \"issuer\": \"elasticsearch\",
    \"start_date_in_millis\": -1
  }
}"
  }


  let(:valid_xpack_response) {
    {
      "license" => {
        "status" => license_status,
        "uid" => "9a48c67c-ce2c-4169-97bf-37d324b8ab80",
        "type"=> license_type,
        "expiry_date_in_millis" => license_expiry_in_millis
      },
      "features" => {
        "security" => {
          "description" => "Security for the Elastic Stack",
          "available" => true,
          "enabled" => true
        }
      }
    }
  }

  let(:no_xpack_response) {
    LogStash::Json.load("{
          \"error\": {
            \"root_cause\": [
              {
                \"type\": \"index_not_found_exception\",
                \"reason\": \"no such index\",
                \"resource.type\": \"index_or_alias\",
                \"resource.id\": \"_xpack\",
                \"index_uuid\": \"_na_\",
                \"index\": \"_xpack\"
              }],
            \"type\": \"index_not_found_exception\",
            \"reason\": \"no such index\",
            \"resource.type\": \"index_or_alias\",
            \"resource.id\": \"_xpack\",
            \"index_uuid\": \"_na_\",
            \"index\": \"_xpack\"
          },
          \"status\": 404
        }")
  }


  let(:settings) do
    {
      "xpack.management.enabled" => true,
      "xpack.management.pipeline.id" => "main",
      "xpack.management.elasticsearch.hosts" => elasticsearch_url,
      "xpack.management.elasticsearch.username" => elasticsearch_username,
      "xpack.management.elasticsearch.password" => elasticsearch_password,
    }
  end

  before do
    extension.additionals_settings(system_settings)
    apply_settings(settings, system_settings)
  end

  subject { described_class.new(system_settings) }

  describe ".new" do
    before do
      allow_any_instance_of(described_class).to receive(:setup_license_checker)
      allow_any_instance_of(described_class).to receive(:license_check)
    end

    context "when password isn't set" do
      let(:settings) do
        {
          "xpack.management.enabled" => true,
          "xpack.management.pipeline.id" => "main",
          "xpack.management.elasticsearch.hosts" => elasticsearch_url,
          "xpack.management.elasticsearch.username" => elasticsearch_username,
          #"xpack.management.elasticsearch.password" => elasticsearch_password,
        }
      end

      it "should raise an ArgumentError" do
        expect { described_class.new(system_settings) }.to raise_error(ArgumentError)
      end
    end

    context "cloud settings" do
      let(:cloud_name) { 'abcdefghijklmnopqrstuvxyz' }
      let(:cloud_domain) { 'elastic.co' }
      let(:cloud_id) { "label:#{Base64.urlsafe_encode64("#{cloud_domain}$#{cloud_name}$ignored")}" }

      let(:settings) do
        {
            "xpack.management.enabled" => true,
            "xpack.management.pipeline.id" => "main",
            "xpack.management.elasticsearch.cloud_id" => cloud_id,
            "xpack.management.elasticsearch.cloud_auth" => "#{elasticsearch_username}:#{elasticsearch_password}"
        }
      end

      it "should not raise an ArgumentError" do
        expect { described_class.new(system_settings) }.not_to raise_error
      end

      context "when cloud_auth isn't set" do
        let(:settings) do
          {
              "xpack.management.enabled" => true,
              "xpack.management.pipeline.id" => "main",
              "xpack.management.elasticsearch.cloud_id" => cloud_id,
              #"xpack.management.elasticsearch.cloud_auth" => "#{elasticsearch_username}:#{elasticsearch_password}"
          }
        end

        it "will rely on username and password settings" do
          # since cloud_id and cloud_auth are simply containers for host and username/password
          # both could be set independently and if cloud_auth is not set then authn will be done
          # using the provided username/password settings, which can be set or not if not auth is
          # required.
          expect { described_class.new(system_settings) }.to_not raise_error
        end
      end
    end
  end

  describe "#fetch_config" do
    let(:mock_client)  { double("http_client") }

    before do
      expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
      allow(mock_license_client).to receive(:get).with('_xpack').and_return(valid_xpack_response)
      allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:client).and_return(mock_license_client)
    end

    it "generates the path to get the configuration" do
      expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/apache,nginx").and_return(LogStash::Json.load("{}"))
      subject.fetch_config(["apache", "nginx"])
    end
  end

  describe "#match?" do
    subject { described_class.new(system_settings) }
    # we are testing the arguments here, not the license checker
    before do
      allow_any_instance_of(described_class).to receive(:setup_license_checker)
      allow_any_instance_of(described_class).to receive(:license_check)
    end

    context "when enabled" do
      let(:settings) do
        {
          "xpack.management.enabled" => true,
          "xpack.management.elasticsearch.username" => "testuser",
          "xpack.management.elasticsearch.password" => "testpassword"
        }
      end

      it "returns true" do
        expect(subject.match?).to be_truthy
      end
    end

    context "when disabled" do
      let(:settings) { {"xpack.management.enabled" => false} }

      it "returns false" do
        expect(subject.match?).to be_falsey
      end
    end
  end

  describe "#pipeline_configs" do
    let(:pipeline_id) { "apache" }
    let(:mock_client)  { double("http_client") }
    let(:settings) { super.merge({ "xpack.management.pipeline.id" => pipeline_id }) }

    before do
      allow(mock_client).to receive(:get).with(instance_of(String)).and_return(LogStash::Json.load(elasticsearch_response))
      allow(mock_license_client).to receive(:get).with('_xpack').and_return(valid_xpack_response)
      allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:client).and_return(mock_license_client)

    end

    context "with one `pipeline_id` configured" do
      context "when successfully fetching a remote configuration" do

        before :each do
          expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
        end

        let(:config) { "input { generator {} } filter { mutate {} } output { }" }
        let(:whitelisted_pipeline_setting_name) {"pipeline.workers"}
        let(:whitelisted_pipeline_setting_value) {"99"}
        let(:non_whitelisted_pipeline_setting_name) {"pipeline.output.workers"}
        let(:non_whitelisted_pipeline_setting_value) {"99"}
        let(:invalid_pipeline_setting) {"nonsensical.invalid.setting"}
        let(:elasticsearch_response) {
          %{
          {
            "#{pipeline_id}" : {
              "username": "log.stash",
              "modified_timestamp":"2017-02-28T23:02:17.023Z",
              "pipeline_metadata":{
                "version":5,
                "type":"logstash_pipeline",
                "username":"elastic"
              },
              "pipeline":"#{config}",
              "pipeline_settings": {
                "#{whitelisted_pipeline_setting_name}":#{whitelisted_pipeline_setting_value},
                "#{non_whitelisted_pipeline_setting_name}":#{non_whitelisted_pipeline_setting_value},
                "#{invalid_pipeline_setting}":-9999
              }
            }
          }
          }
        }

        it "returns a valid pipeline config" do
          pipeline_config = subject.pipeline_configs

          expect(pipeline_config.first.config_string).to match(config)
          expect(pipeline_config.first.pipeline_id.to_sym).to eq(pipeline_id.to_sym)
        end

        it "ignores non-whitelisted and invalid settings" do
          pipeline_config = subject.pipeline_configs
          settings_hash = pipeline_config[0].settings.to_hash

          expect(settings_hash[whitelisted_pipeline_setting_name]).to eq(whitelisted_pipeline_setting_value.to_i)
          expect(settings_hash[non_whitelisted_pipeline_setting_name]).not_to eq(non_whitelisted_pipeline_setting_value.to_i)
          expect(settings_hash[invalid_pipeline_setting]).to be_falsey
        end
      end

      context 'when the license has expired' do
        let(:config) { "input { generator {} } filter { mutate {} } output { }" }
        let(:elasticsearch_response) { "{\"#{pipeline_id}\":{\"username\":\"log.stash\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\"},\"pipeline\":\"#{config}\",\"pipeline_settings\":{\"pipeline.batch.delay\":\"50\"}}}" }
        let(:license_status) { 'expired'}
        let(:license_expiry_date) { Time.now - (60 * 60 * 24)}

        before :each do
          expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
        end

        it "returns a valid pipeline config" do
          pipeline_config = subject.pipeline_configs

          expect(pipeline_config.first.config_string).to match(config)
          expect(pipeline_config.first.pipeline_id.to_sym).to eq(pipeline_id.to_sym)
        end
      end

      context 'when the license server is not available' do
        let(:config) { "input { generator {} } filter { mutate {} } output { }" }
        let(:elasticsearch_response) { "{\"#{pipeline_id}\":{\"username\":\"log.stash\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\"},\"pipeline\":\"#{config}\",\"pipeline_settings\":{\"pipeline.batch.delay\":\"50\"}}}" }

        before :each do
          allow(mock_license_client).to receive(:get).with('_xpack').and_raise("An error is here")
          allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:build_client).and_return(mock_license_client)
        end

        it 'should raise an error' do
          expect{subject.pipeline_configs}.to raise_error(LogStash::LicenseChecker::LicenseError)
        end
      end

      context 'when the xpack is not installed' do
        let(:config) { "input { generator {} } filter { mutate {} } output { }" }
        let(:elasticsearch_response) { "{\"#{pipeline_id}\":{\"username\":\"log.stash\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\"},\"pipeline\":\"#{config}\",\"pipeline_settings\":{\"pipeline.batch.delay\":\"50\"}}}" }

        before :each do
          expect(mock_license_client).to receive(:get).with('_xpack').and_return(no_xpack_response)
          allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:build_client).and_return(mock_license_client)
        end

        it 'should raise an error' do
          expect{subject.pipeline_configs}.to raise_error(LogStash::LicenseChecker::LicenseError)
        end
      end

      describe 'security enabled/disabled in Elasticsearch' do
        let(:config) { "input { generator {} } filter { mutate {} } output { }" }
        let(:elasticsearch_response) { "{\"#{pipeline_id}\":{\"username\":\"log.stash\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\"},\"pipeline\":\"#{config}\",\"pipeline_settings\":{\"pipeline.batch.delay\":\"50\"}}}" }

        let(:xpack_response) do
          {
            "license"=> {
              "status"=> license_status,
              "uid"=> "9a48c67c-ce2c-4169-97bf-37d324b8ab80",
              "type"=> license_type,
              "expiry_date_in_millis"=> license_expiry_in_millis
            },
            "features" => {
              "security" => {
                "description" => "Security for the Elastic Stack",
                "available" => true,
                "enabled" => security_enabled
              }
            }
          }
        end

        before :each do
          allow(mock_license_client).to receive(:get).with('_xpack').and_return(xpack_response)
          allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:build_client).and_return(mock_license_client)
        end

        context 'when security is disabled in Elasticsearch' do
          let(:security_enabled) { false }
          it 'should raise an error' do
            expect { subject.pipeline_configs }.to raise_error(LogStash::LicenseChecker::LicenseError)
          end
        end

        context 'when security is enabled in Elasticsearch' do
          let(:security_enabled) { true }
          it 'should not raise an error' do
            expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
            expect { subject.pipeline_configs }.not_to raise_error
          end
        end
      end


      context "With an invalid basic license, it should raise an error" do
        let(:config) { "input { generator {} } filter { mutate {} } output { }" }
        let(:elasticsearch_response) { "{\"#{pipeline_id}\":{\"username\":\"log.stash\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\"},\"pipeline\":\"#{config}\",\"pipeline_settings\":{\"pipeline.batch.delay\":\"50\"}}}" }
        let(:license_type) { 'basic' }

        it 'should raise an error' do
          expect{subject.pipeline_configs}.to raise_error(LogStash::LicenseChecker::LicenseError)
        end
      end

      # config management can be used with any license type except basic
      (::LogStash::LicenseChecker::LICENSE_TYPES - ["basic"]).each do |license_type|
        context "With a valid #{license_type} license, it should return a pipeline" do

          before do
            expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
          end

          let(:config) { "input { generator {} } filter { mutate {} } output { }" }
          let(:elasticsearch_response) { "{\"#{pipeline_id}\":{\"username\":\"log.stash\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\"},\"pipeline\":\"#{config}\",\"pipeline_settings\":{\"pipeline.batch.delay\":\"50\"}}}" }
          let(:license_type) { license_type }

          it "returns a valid pipeline config" do
            pipeline_config = subject.pipeline_configs

            expect(pipeline_config.first.config_string).to match(config)
            expect(pipeline_config.first.pipeline_id.to_sym).to eq(pipeline_id.to_sym)
          end
        end
      end
    end

    context "with multiples `pipeline_id` configured" do

      before do
        allow(mock_client).to receive(:get).with(instance_of(String)).and_return(LogStash::Json.load(elasticsearch_response))
        expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
      end

      context "when successfully fetching multiple remote configuration" do
        let(:pipelines) do
          {
            "apache" => config_apache,
            "firewall" => config_firewall
          }
        end
        let(:pipeline_id) { pipelines.keys }

        let(:config_apache) { "input { generator { id => '123'} } filter { mutate {} } output { }" }
        let(:config_firewall) { "input { generator { id => '321' } } filter { mutate {} } output { }" }
        let(:elasticsearch_response) do
          content = "{"
          content << pipelines.collect do |pipeline_id, config|
            "\"#{pipeline_id}\":{\"username\":\"log.stash\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\"},\"pipeline\":\"#{config}\",\"pipeline_settings\":{\"pipeline.batch.delay\":\"50\"}}"
          end.join(",")
          content << "}"
          content
        end

        it "returns a valid pipeline config" do
          pipeline_config = subject.pipeline_configs

          expect(pipeline_config.collect(&:config_string)).to include(*pipelines.values)
          expect(pipeline_config.map(&:pipeline_id).collect(&:to_sym)).to include(*pipelines.keys.collect(&:to_sym))
        end
      end
    end

    context "when the configuration is not found" do
      let(:elasticsearch_response) { "{}" }

      before do
        expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
      end

      it "returns no pipeline config" do
        expect(subject.pipeline_configs).to be_empty
      end
    end

    context "when any error returned from elasticsearch" do
      let(:elasticsearch_response){"{\"error\" : \"no handler found for uri [/_logstash/pipelines?pretty] and method [GET]\"}" }

      before do
        expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
      end

      it "raises a `RemoteConfigError`" do
        expect { subject.pipeline_configs }.to raise_error /no handler found/
      end
    end

    context "when exception occur" do
      let(:elasticsearch_response) { "" }

      before do
        expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
      end

      it "raises the exception upstream" do
        expect(mock_client).to receive(:get).with(instance_of(String)).and_raise("Something bad")
        expect { subject.pipeline_configs }.to raise_error /Something bad/
      end
    end
  end
end
