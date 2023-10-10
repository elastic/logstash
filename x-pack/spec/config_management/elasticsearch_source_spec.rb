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
  let(:system_indices_api) { LogStash::ConfigManagement::SystemIndicesFetcher::SYSTEM_INDICES_API_PATH }
  let(:system_indices_url_regex) { Regexp.new("^#{system_indices_api}") }
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
        "type" => license_type,
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
    {"error" =>
       {"root_cause" =>
          [{"type" => "index_not_found_exception",
            "reason" => "no such index",
            "resource.type" => "index_or_alias",
            "resource.id" => "_xpack",
            "index_uuid" => "_na_",
            "index" => "_xpack"}],
        "type" => "index_not_found_exception",
        "reason" => "no such index",
        "resource.type" => "index_or_alias",
        "resource.id" => "_xpack",
        "index_uuid" => "_na_",
        "index" => "_xpack"},
     "status" => 404}
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

  let(:es_version_response) { es_version_8_response }
  let(:es_version_8_response) { cluster_info("8.0.0-SNAPSHOT") }
  let(:es_version_7_9_response) { cluster_info("7.9.1") }

  let(:elasticsearch_7_9_err_response) {
    {"error" =>
         {"root_cause" =>
              [{"type" => "parse_exception",
                "reason" => "request body or source parameter is required"}],
          "type" => "parse_exception",
          "reason" => "request body or source parameter is required"},
     "status" => 400}
  }

  let(:elasticsearch_8_err_response) {
    {"error" =>
         {"root_cause" =>
              [{"type" => "index_not_found_exception",
                "reason" => "no such index [.logstash]",
                "resource.type" => "index_expression",
                "resource.id" => ".logstash",
                "index_uuid" => "_na_",
                "index" => ".logstash"}],
          "type" => "index_not_found_exception",
          "reason" => "no such index [.logstash]",
          "resource.type" => "index_expression",
          "resource.id" => ".logstash",
          "index_uuid" => "_na_",
          "index" => ".logstash"},
     "status" => 404}
  }

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

    context "valid settings" do
      let(:settings) do
        {
          "xpack.management.enabled" => true,
          "xpack.management.pipeline.id" => "main",
          "xpack.management.elasticsearch.hosts" => elasticsearch_url,
          "xpack.management.elasticsearch.username" => elasticsearch_username,
          "xpack.management.elasticsearch.password" => elasticsearch_password,
        }
      end

      # This spec is certainly indirect, and assumes that communication with Elasticsearch
      # will be done through an ES-output HttpClient available at described_class.client
      it 'creates an Elasticsearch HttpClient with product origin custom headers' do
        internal_client = subject.send(:client) # internal reach
        expect(internal_client)
          .to be_a_kind_of(LogStash::Outputs::ElasticSearch::HttpClient)
          .and(have_attributes(:client_settings => hash_including(:headers => hash_including("x-elastic-product-origin" => "logstash"))))
      end
    end
  end

  describe LogStash::ConfigManagement::SystemIndicesFetcher do
    subject { described_class.new }

    describe "system indices api" do
      let(:mock_client)  { double("http_client") }
      let(:config) { "input { generator { count => 100 } tcp { port => 6005 } } output { }}" }
      let(:es_version_8_2) { { major: 8, minor: 2} }
      let(:es_version_8_3) { { major: 8, minor: 3} }
      let(:es_version_9_0) { { major: 9, minor: 0} }
      let(:pipeline_id) { "super_generator" }
      let(:elasticsearch_response) { {"#{pipeline_id}" => {"pipeline" => "#{config}"}} }
      let(:all_pipelines) { JSON.parse(::File.read(::File.join(::File.dirname(__FILE__), "fixtures", "pipelines.json"))) }
      let(:mock_logger) { double("fetcher's logger") }

      before(:each) {
        allow(subject).to receive(:logger).and_return(mock_logger)
      }

      it "#fetch_config from ES v8.2" do
        expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(elasticsearch_response.clone)
        expect(subject.fetch_config(es_version_8_2, [pipeline_id], mock_client)).to eq(elasticsearch_response)
        expect(subject.get_single_pipeline_setting(pipeline_id)).to eq({"pipeline" => "#{config}"})
      end

      it "#fetch_config from ES v8.3" do
        expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}?id=#{pipeline_id}").and_return(elasticsearch_response.clone)
        expect(subject.fetch_config(es_version_8_3, [pipeline_id], mock_client)).to eq(elasticsearch_response)
        expect(subject.get_single_pipeline_setting(pipeline_id)).to eq({"pipeline" => "#{config}"})
      end

      it "#fetch_config from ES v9.0" do
        expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}?id=#{pipeline_id}").and_return(elasticsearch_response.clone)
        expect(subject.fetch_config(es_version_9_0, [pipeline_id], mock_client)).to eq(elasticsearch_response)
        expect(subject.get_single_pipeline_setting(pipeline_id)).to eq({"pipeline" => "#{config}"})
      end

      it "#fetch_config should raise error" do
        expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(elasticsearch_8_err_response.clone)
        expect { subject.fetch_config(es_version_8_2, ["apache", "nginx"], mock_client) }.to raise_error(LogStash::ConfigManagement::ElasticsearchSource::RemoteConfigError)
      end

      describe "wildcard" do
        it "should accept * " do
          expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(all_pipelines.clone)
          expect(mock_logger).to receive(:warn).never
          expect(subject.fetch_config(es_version_8_2, ["*"], mock_client).keys.length).to eq(all_pipelines.keys.length)
        end

        it "should accept multiple * in one pattern " do
          expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(all_pipelines.clone)
          expect(mock_logger).to receive(:warn).never
          expect(subject.fetch_config(es_version_8_2, ["host*_pipeline*"], mock_client).keys).to eq(["host1_pipeline1", "host1_pipeline2", "host2_pipeline1", "host2_pipeline2"])
        end

        it "should give unique pipeline with multiple wildcard patterns" do
          expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(all_pipelines.clone)
          expect(subject).to receive(:log_pipeline_not_found).with(["*pipeline*"]).exactly(1)
          expect(subject.fetch_config(es_version_8_2, ["host1_pipeline*", "host2_pipeline*", "*pipeline*"], mock_client).keys).to eq(["host1_pipeline1", "host1_pipeline2", "host2_pipeline1", "host2_pipeline2"])
        end

        it "should accept a mix of wildcard and non wildcard pattern" do
          expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(all_pipelines.clone)
          expect(mock_logger).to receive(:warn).never
          expect(subject.fetch_config(es_version_8_2, ["host1_pipeline*", "host2_pipeline*", "super_generator"], mock_client).keys).to eq(["super_generator", "host1_pipeline1", "host1_pipeline2", "host2_pipeline1", "host2_pipeline2"])
        end

        it "should log unmatched pattern" do
          pipeline_ids = ["very_awesome_pipeline", "*whatever*"]
          expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(all_pipelines.clone)
          expect(subject).to receive(:log_pipeline_not_found).with(pipeline_ids).exactly(1)
          expect(subject.fetch_config(es_version_8_2, pipeline_ids, mock_client)).to eq({})
        end

        it "should log unmatched pattern and return matched pipeline" do
          pipeline_ids = ["very_awesome_pipeline", "*whatever*"]
          expect(mock_client).to receive(:get).with("#{described_class::SYSTEM_INDICES_API_PATH}/").and_return(all_pipelines.clone)
          expect(subject).to receive(:log_pipeline_not_found).with(pipeline_ids).exactly(1)
          expect(subject.fetch_config(es_version_8_2, pipeline_ids + [pipeline_id], mock_client)).to eq(elasticsearch_response)
        end
      end
    end
  end

  describe LogStash::ConfigManagement::LegacyHiddenIndicesFetcher do
    subject { described_class.new }

    describe "legacy api" do
      let(:mock_client)  { double("http_client") }
      let(:config) { "input { generator { count => 100 } tcp { port => 6005 } } output {  }}" }
      let(:another_config) { "input { generator { count => 100 } tcp { port => 6006 } } output {  }}" }
      let(:empty_es_version) { {
        # will not be used
      } }
      let(:pipeline_id) { "super_generator" }
      let(:another_pipeline_id) { "another_generator" }
      let(:elasticsearch_response) {
        {"docs" =>
             [{"_index" => ".logstash",
               "_id" => "#{pipeline_id}",
               "_version" => 2,
               "_seq_no" => 2,
               "_primary_term" => 1,
               "found" => true,
               "_source" =>
                   {"pipeline" => "#{config}"}},
              {"_index" => ".logstash",
               "_id" => "#{another_pipeline_id}",
               "_version" => 2,
               "_seq_no" => 3,
               "_primary_term" => 1,
               "found" => true,
               "_source" =>
                   {"pipeline" => "#{another_config}"}},
              {"_index" => ".logstash", "_id" => "not_exists", "found" => false}]}
      }

      let(:formatted_es_response) {
        {"super_generator" => {"_index" => ".logstash", "_id" => "super_generator", "_version" => 2, "_seq_no" => 2, "_primary_term" => 1, "found" => true, "_source" => {"pipeline" => "input { generator { count => 100 } tcp { port => 6005 } } output {  }}"}}}
      }

      let(:mock_logger) { double("fetcher's logger") }

      before(:each) {
        allow(subject).to receive(:logger).and_return(mock_logger)
        allow(mock_logger).to receive(:debug)
      }

      it "#fetch_config" do
        expect(mock_client).to receive(:post).with("#{described_class::PIPELINE_INDEX}/_mget", {}, "{\"docs\":[{\"_id\":\"#{pipeline_id}\"},{\"_id\":\"#{another_pipeline_id}\"}]}").and_return(elasticsearch_response)
        expect(mock_logger).to receive(:warn).never
        expect(subject.fetch_config(empty_es_version, [pipeline_id, another_pipeline_id], mock_client).size).to eq(2)
        expect(subject.get_single_pipeline_setting(pipeline_id)).to eq({"pipeline" => "#{config}"})
        expect(subject.get_single_pipeline_setting(another_pipeline_id)).to eq({"pipeline" => "#{another_config}"})
      end

      it "#fetch_config should raise error" do
        expect(mock_client).to receive(:post).with("#{described_class::PIPELINE_INDEX}/_mget", {}, "{\"docs\":[{\"_id\":\"#{pipeline_id}\"},{\"_id\":\"#{another_pipeline_id}\"}]}").and_return(elasticsearch_7_9_err_response)
        expect(mock_logger).to receive(:warn).never
        expect { subject.fetch_config(empty_es_version, [pipeline_id, another_pipeline_id], mock_client) }.to raise_error(LogStash::ConfigManagement::ElasticsearchSource::RemoteConfigError)
      end

      it "#fetch_config should raise error when response is empty" do
        expect(mock_client).to receive(:post).with("#{described_class::PIPELINE_INDEX}/_mget", {}, "{\"docs\":[{\"_id\":\"#{pipeline_id}\"},{\"_id\":\"#{another_pipeline_id}\"}]}").and_return(LogStash::Json.load("{}"))
        expect { subject.fetch_config(empty_es_version, [pipeline_id, another_pipeline_id], mock_client) }.to raise_error(LogStash::ConfigManagement::ElasticsearchSource::RemoteConfigError)
      end

      it "#fetch_config should log unmatched pipeline id" do
        expect(mock_client).to receive(:post).with("#{described_class::PIPELINE_INDEX}/_mget", {}, "{\"docs\":[{\"_id\":\"#{pipeline_id}\"},{\"_id\":\"#{another_pipeline_id}\"},{\"_id\":\"*\"}]}").and_return(elasticsearch_response)
        expect(subject).to receive(:log_pipeline_not_found).with(["*"]).exactly(1)
        expect(mock_logger).to receive(:warn).with(/is not supported in Elasticsearch version < 7\.10/)
        expect(subject.fetch_config(empty_es_version, [pipeline_id, another_pipeline_id, "*"], mock_client).size).to eq(2)
        expect(subject.get_single_pipeline_setting(pipeline_id)).to eq({"pipeline" => "#{config}"})
        expect(subject.get_single_pipeline_setting(another_pipeline_id)).to eq({"pipeline" => "#{another_config}"})
      end

      it "#format_response should return pipelines" do
        result = subject.send(:format_response, elasticsearch_response)
        expect(result.size).to eq(2)
        expect(result.has_key?(pipeline_id)).to be_truthy
        expect(result.has_key?(another_pipeline_id)).to be_truthy
      end

      it "should log wildcard warning" do
        expect(mock_logger).to receive(:warn).with("wildcard '*' in xpack.management.pipeline.id is not supported in Elasticsearch version < 7.10")
        subject.send(:log_wildcard_unsupported, [pipeline_id, another_pipeline_id, "*"])
      end
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
    let(:settings) { super().merge({ "xpack.management.pipeline.id" => pipeline_id }) }
    let(:config) { "input { generator {} } filter { mutate {} } output { }" }
    let(:username) { 'log.stash' }
    let(:pipeline_settings) do
      {
        "pipeline.batch.delay"       => "50",
        "pipeline.workers"           => "99",
        "pipeline.ordered"           => "false",
        "pipeline.ecs_compatibility" => "v1",

        # invalid settings to be ignored...
        "pipeline.output.workers"    => "99",
        "nonsensical.invalid.setting" => "-9999",
      }
    end
    let(:pipeline_metadata) do
      {
        "version" => 5,
        "type" => "logstash_pipeline",
      }
    end
    let(:elasticsearch_response) { elasticsearch_8_response }
    let(:elasticsearch_8_response) do
      {
        pipeline_id => {
          username: username,
          modified_timestamp: "2017-02-28T23:02:17.023Z",
          pipeline_metadata: pipeline_metadata,
          pipeline: config,
          pipeline_settings: pipeline_settings,
        }
      }.to_json
    end

    let(:elasticsearch_7_9_response) do
      {
        docs: [{
                 _index: ".logstash",
                 _type: "pipelines",
                 _id: pipeline_id,
                 _version: 8,
                 found: true,
                 _source: {
                   id: pipeline_id,
                   description: "Process apache logs",
                   modified_timestamp: "2017-02-28T23:02:17.023Z",
                   pipeline_metadata: pipeline_metadata.merge(username: username),
                   pipeline: config,
                   pipeline_settings: pipeline_settings,
                 }
               }]
      }.to_json
    end
    let(:es_path) { ".logstash/_mget" }
    let(:request_body_string) { LogStash::Json.dump({ "docs" => [{ "_id" => pipeline_id }] }) }

    before do
      allow(mock_client).to receive(:get).with(system_indices_url_regex).and_return(LogStash::Json.load(elasticsearch_response))
      allow(mock_client).to receive(:get).with("/").and_return(es_version_response)
      allow(mock_client).to receive(:post).with(es_path, {}, request_body_string).and_return(LogStash::Json.load(elasticsearch_7_9_response))
      allow(mock_license_client).to receive(:get).with('_xpack').and_return(valid_xpack_response)
      allow(mock_license_client).to receive(:get).with('/').and_return(cluster_info(LOGSTASH_VERSION))

      allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:client).and_return(mock_license_client)
    end

    describe "system indices [8] and legacy api [7.9]" do
      [8, 7.9].each { |es_version|
        let(:elasticsearch_response) { (es_version >= 8) ? elasticsearch_8_response : elasticsearch_7_9_response }

        before :each do
          allow(mock_client).to receive(:get).with("/").and_return(es_version >= 8 ? es_version_response : es_version_7_9_response)
        end

        context "with one `pipeline_id` configured [#{es_version}]" do
          context "when successfully fetching a remote configuration" do
            let(:logger_stub) { double("Logger").as_null_object }
            before :each do
              expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
              allow_any_instance_of(described_class).to receive(:logger).and_return(logger_stub)
              allow(mock_client).to receive(:post).with(es_path, {}, request_body_string).and_return(LogStash::Json.load(elasticsearch_7_9_response))
            end

            let(:config) { "input { generator {} } filter { mutate {} } output { }" }

            it "returns a valid pipeline config" do
              pipeline_config = subject.pipeline_configs

              expect(pipeline_config.first.config_string).to match(config)
              expect(pipeline_config.first.pipeline_id.to_sym).to eq(pipeline_id.to_sym)
            end

            it "applies allowed settings and logs warning about ignored settings" do
              pipeline_config = subject.pipeline_configs
              pipeline_settings = pipeline_config[0].settings

              aggregate_failures do
                # explicitly given settings
                expect(pipeline_settings.get_setting("pipeline.workers")).to be_set.and(have_attributes(value: 99))
                expect(pipeline_settings.get_setting("pipeline.batch.delay")).to be_set.and(have_attributes(value: 50))
                expect(pipeline_settings.get_setting("pipeline.ordered")).to be_set.and(have_attributes(value: "false"))
                expect(pipeline_settings.get_setting("pipeline.ecs_compatibility")).to be_set.and(have_attributes(value: "v1"))

                # valid non-provided settings
                expect(pipeline_settings.get_setting("queue.type")).to_not be_set

                # invalid provided settings
                %w(
                  pipeline.output.workers
                  nonsensical.invalid.setting
                ).each do |invalid_setting|
                  expect(pipeline_settings.registered?(invalid_setting)).to be false
                  expect(logger_stub).to have_received(:warn).with(/Ignoring .+ '#{Regexp.quote(invalid_setting)}'/)
                end
              end
            end
          end

          context "when the license has expired [#{es_version}]" do
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

          context "when the license server is not available [#{es_version}]" do
            before :each do
              allow(mock_license_client).to receive(:get).with('_xpack').and_raise("An error is here")
              allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:build_client).and_return(mock_license_client)
            end

            it 'should raise an error' do
              expect {subject.pipeline_configs}.to raise_error(LogStash::LicenseChecker::LicenseError)
            end
          end

          context "when the xpack is not installed [#{es_version}]" do
            before :each do
              expect(mock_license_client).to receive(:get).with('_xpack').and_return(no_xpack_response)
              allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:build_client).and_return(mock_license_client)
            end

            it 'should raise an error' do
              expect {subject.pipeline_configs}.to raise_error(LogStash::LicenseChecker::LicenseError)
            end
          end

          context "when ES is serverless" do
            before do
              expect(mock_license_client).to receive(:get).with('/').and_return(cluster_info(LOGSTASH_VERSION, 'serverless'))
            end

            it "passes license check" do
              expect(subject.license_check).to be_truthy
            end
          end

          describe "security enabled/disabled in Elasticsearch [#{es_version}]" do
            let(:xpack_response) do
              {
                  "license" => {
                      "status" => license_status,
                      "uid" => "9a48c67c-ce2c-4169-97bf-37d324b8ab80",
                      "type" => license_type,
                      "expiry_date_in_millis" => license_expiry_in_millis
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

            context "when security is disabled in Elasticsearch [#{es_version}]" do
              let(:security_enabled) { false }
              it 'should raise an error' do
                expect { subject.pipeline_configs }.to raise_error(LogStash::LicenseChecker::LicenseError)
              end
            end

            context "when security is enabled in Elasticsearch [#{es_version}]" do
              let(:security_enabled) { true }
              it 'should not raise an error' do
                expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
                expect { subject.pipeline_configs }.not_to raise_error
              end
            end
          end

          context "With an invalid basic license, it should raise an error [#{es_version}]" do
            let(:license_type) { 'basic' }

            it 'should raise an error' do
              expect {subject.pipeline_configs}.to raise_error(LogStash::LicenseChecker::LicenseError)
            end
          end

          # config management can be used with any license type except basic
          (::LogStash::LicenseChecker::LICENSE_TYPES - ["basic"]).each do |license_type|
            context "With a valid #{license_type} license, it should return a pipeline  [#{es_version}]" do
              before do
                expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
              end

              let(:license_type) { license_type }

              it "returns a valid pipeline config" do
                pipeline_config = subject.pipeline_configs

                expect(pipeline_config.first.config_string).to match(config)
                expect(pipeline_config.first.pipeline_id.to_sym).to eq(pipeline_id.to_sym)
              end
            end
          end
        end

        context "with multiples `pipeline_id` configured [#{es_version}]" do
          before do
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

            let(:elasticsearch_7_9_response) do
              content = "{ \"docs\":["
              content << pipelines.collect do |pipeline_id, config|
                "{\"_index\":\".logstash\",\"_type\":\"pipelines\",\"_id\":\"#{pipeline_id}\",\"_version\":8,\"found\":true,\"_source\":{\"id\":\"apache\",\"description\":\"Process apache logs\",\"modified_timestamp\":\"2017-02-28T23:02:17.023Z\",\"pipeline_metadata\":{\"version\":5,\"type\":\"logstash_pipeline\",\"username\":\"elastic\"},\"pipeline\":\"#{config}\"}}"
              end.join(",")
              content << "]}"
              content
            end
            let(:request_body_string) { LogStash::Json.dump({ "docs" => pipeline_id.collect { |pipeline_id| { "_id" => pipeline_id } } }) }

            it "returns a valid pipeline config" do
              pipeline_config = subject.pipeline_configs

              expect(pipeline_config.collect(&:config_string)).to include(*pipelines.values)
              expect(pipeline_config.map(&:pipeline_id).collect(&:to_sym)).to include(*pipelines.keys.collect(&:to_sym))
            end
          end
        end

        context "when the configuration is not found [#{es_version}]" do
          let(:elasticsearch_8_response) { "{}" }
          let(:elasticsearch_7_9_response) { "{ \"docs\": [{\"_index\":\".logstash\",\"_type\":\"pipelines\",\"_id\":\"donotexist\",\"found\":false}]}" }

          before do
            expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
          end

          it "returns no pipeline config" do
            expect(subject.pipeline_configs).to be_empty
          end
        end

        context "when any error returned from elasticsearch [#{es_version}]" do
          let(:elasticsearch_8_response) {"{\"error\" : \"no handler found for uri [/_logstash/pipelines?pretty] and method [GET]\"}" }
          let(:elasticsearch_7_9_response) { '{ "error":{"root_cause":[{"type":"illegal_argument_exception","reason":"No endpoint or operation is available at [testing_ph]"}],"type":"illegal_argument_exception","reason":"No endpoint or operation is available at [testing_ph]"},"status":400}' }

          before do
            expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
          end

          it "raises a `RemoteConfigError`" do
            expect { subject.pipeline_configs }.to raise_error LogStash::ConfigManagement::ElasticsearchSource::RemoteConfigError
          end
        end
      }
    end

    describe "create pipeline fetcher by es version" do
      it "should give SystemIndicesFetcher in [8]" do
        expect(subject.get_pipeline_fetcher({ major: 8, minor: 2 })).to be_an_instance_of LogStash::ConfigManagement::SystemIndicesFetcher
      end

      it "should give SystemIndicesFetcher in [7.10]" do
        expect(subject.get_pipeline_fetcher({ major: 7, minor: 10 })).to be_an_instance_of LogStash::ConfigManagement::SystemIndicesFetcher
      end

      it "should give LegacyHiddenIndicesFetcher in [7.9]" do
        expect(subject.get_pipeline_fetcher({ major: 7, minor: 9 })).to be_an_instance_of LogStash::ConfigManagement::LegacyHiddenIndicesFetcher
      end
    end

    describe "when exception occur" do
      let(:elasticsearch_response) { "" }

      before do
        expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
      end

      it "raises the exception upstream in [8]" do
        allow(mock_client).to receive(:get).with("/").and_return(es_version_response)
        allow(mock_client).to receive(:get).with(system_indices_url_regex).and_raise("Something bad")
        expect { subject.pipeline_configs }.to raise_error /Something bad/
      end

      it "raises the exception upstream in [7.9]" do
        allow(mock_client).to receive(:get).with("/").and_return(es_version_7_9_response)
        expect(mock_client).to receive(:post).with(es_path, {}, request_body_string).and_raise("Something bad")
        expect { subject.pipeline_configs }.to raise_error /Something bad/
      end
    end
  end

  describe "#get_es_version" do
    let(:mock_client)  { double("http_client") }

    before do
      expect_any_instance_of(described_class).to receive(:build_client).and_return(mock_client)
      allow(mock_license_client).to receive(:get).with('/').and_return(cluster_info(LOGSTASH_VERSION))
      allow(mock_license_client).to receive(:get).with('_xpack').and_return(valid_xpack_response)
      allow_any_instance_of(LogStash::LicenseChecker::LicenseReader).to receive(:client).and_return(mock_license_client)
    end

    it "responses [7.10] ES version" do
      expected_version = { major: 7, minor: 10 }
      allow(mock_client).to receive(:get).with("/").and_return(cluster_info("7.10.0-SNAPSHOT"))
      expect(subject.get_es_version).to eq expected_version
    end

    it "responses [8.0] ES version" do
      expected_version = { major: 8, minor: 0 }
      allow(mock_client).to receive(:get).with("/").and_return(es_version_8_response)
      expect(subject.get_es_version).to eq expected_version
    end

    it "responses with an error" do
      allow(mock_client).to receive(:get).with("/").and_return(elasticsearch_8_err_response)
      expect { subject.get_es_version }.to raise_error(LogStash::ConfigManagement::ElasticsearchSource::RemoteConfigError)
    end
  end
end
