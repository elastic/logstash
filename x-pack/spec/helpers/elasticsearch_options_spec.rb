# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "spec_helper"
require "logstash/json"
require "logstash/runner"
require 'helpers/elasticsearch_options'
require "license_checker/license_manager"
require 'monitoring/monitoring'

shared_examples "elasticsearch options hash is populated without security" do
  it "with username, hosts and password" do
      expect(test_class.es_options_from_settings_or_modules('monitoring', system_settings)).to include(
                                                                                                   "hosts" => expected_url,
                                                                                                   "user" => expected_username,
                                                                                                   "password" => expected_password
                                                                                               )
  end
end

shared_examples 'elasticsearch options hash is populated with secure options' do
  context "with ca" do
    let(:elasticsearch_ca) { Stud::Temporary.file.path }
    let(:settings) { super().merge({ "xpack.monitoring.elasticsearch.ssl.certificate_authority" => elasticsearch_ca })}

    it "creates the elasticsearch output options hash" do
      expect(test_class.es_options_from_settings('monitoring', system_settings)).to include(
                                                                                        "hosts" => elasticsearch_url,
                                                                                        "user" => elasticsearch_username,
                                                                                        "password" => elasticsearch_password,
                                                                                        "ssl_enabled" => true,
                                                                                        "ssl_certificate_authorities" => elasticsearch_ca
                                                                                    )
    end
  end

  context "with ca_trusted_fingerprint" do
    let(:ca_trusted_fingerprint) { SecureRandom.hex(32) }
    let(:settings) { super().merge("xpack.monitoring.elasticsearch.ssl.ca_trusted_fingerprint" => ca_trusted_fingerprint) }

    it "creates the elasticsearch output options hash" do
      expect(test_class.es_options_from_settings('monitoring', system_settings)).to include(
                                                                                      "hosts" => elasticsearch_url,
                                                                                      "user" => elasticsearch_username,
                                                                                      "password" => elasticsearch_password,
                                                                                      "ssl_enabled" => true,
                                                                                      "ca_trusted_fingerprint" => ca_trusted_fingerprint
                                                                                    )
    end
  end

  context "with truststore" do
    let(:elasticsearch_truststore_path) { Stud::Temporary.file.path }
    let(:elasticsearch_truststore_password) { "truststore_password" }
    let(:settings) do
      super().merge({
                      "xpack.monitoring.elasticsearch.ssl.truststore.path" => elasticsearch_truststore_path,
                      "xpack.monitoring.elasticsearch.ssl.truststore.password" => elasticsearch_truststore_password,
                  })
    end

    it "creates the elasticsearch output options hash" do
      expect(test_class.es_options_from_settings('monitoring', system_settings)).to include(
                                                                                        "hosts" => elasticsearch_url,
                                                                                        "user" => elasticsearch_username,
                                                                                        "password" => elasticsearch_password,
                                                                                        "ssl_enabled" => true,
                                                                                        "ssl_truststore_path" => elasticsearch_truststore_path,
                                                                                        "ssl_truststore_password" => elasticsearch_truststore_password
                                                                                    )
    end
  end

  context "with keystore" do
    let(:elasticsearch_keystore_path) { Stud::Temporary.file.path }
    let(:elasticsearch_keystore_password) { "keystore_password" }

    let(:settings) do
      super().merge({
                      "xpack.monitoring.elasticsearch.ssl.keystore.path" => elasticsearch_keystore_path,
                      "xpack.monitoring.elasticsearch.ssl.keystore.password" => elasticsearch_keystore_password,
                  })
    end

    it "creates the elasticsearch output options hash" do
      expect(test_class.es_options_from_settings('monitoring', system_settings)).to include(
                                                                                        "hosts" => elasticsearch_url,
                                                                                        "user" => elasticsearch_username,
                                                                                        "password" => elasticsearch_password,
                                                                                        "ssl_enabled" => true,
                                                                                        "ssl_keystore_path" => elasticsearch_keystore_path,
                                                                                        "ssl_keystore_password" => elasticsearch_keystore_password
                                                                                    )
    end
  end

  context "with certificate and key" do
    let(:elasticsearch_certificate_path) { Stud::Temporary.file.path }
    let(:elasticsearch_key_path) { Stud::Temporary.file.path }

    let(:settings) do
      super().merge({
        "xpack.monitoring.elasticsearch.ssl.certificate" => elasticsearch_certificate_path,
        "xpack.monitoring.elasticsearch.ssl.key" => elasticsearch_key_path,
      })
    end

    it "creates the elasticsearch output options hash" do
      expect(test_class.es_options_from_settings('monitoring', system_settings)).to include(
                                                                                        "hosts" => elasticsearch_url,
                                                                                        "user" => elasticsearch_username,
                                                                                        "password" => elasticsearch_password,
                                                                                        "ssl_enabled" => true,
                                                                                        "ssl_certificate" => elasticsearch_certificate_path,
                                                                                        "ssl_key" => elasticsearch_key_path
                                                                                      )
    end
  end

  context "with cipher suites" do
    context "provided" do
      let(:settings) do
        super().merge({
          "xpack.monitoring.elasticsearch.ssl.cipher_suites" => ["FOO", "BAR"],
        })
      end

      it "creates the elasticsearch output options hash" do
        expect(test_class.es_options_from_settings('monitoring', system_settings)).to include(
                                                                                          "hosts" => elasticsearch_url,
                                                                                          "user" => elasticsearch_username,
                                                                                          "password" => elasticsearch_password,
                                                                                          "ssl_enabled" => true,
                                                                                          "ssl_cipher_suites" => ["FOO", "BAR"],
                                                                                        )
      end
    end

    context "empty" do
      let(:settings) do
        super().merge({
          "xpack.monitoring.elasticsearch.ssl.cipher_suites" => [],
        })
      end

      it "creates the elasticsearch output options hash" do
        expect(test_class.es_options_from_settings('monitoring', system_settings)).to_not have_key("ssl_cipher_suites")
      end
    end
  end
end

describe LogStash::Helpers::ElasticsearchOptions do
  let(:test_class) { Class.new { extend LogStash::Helpers::ElasticsearchOptions } }
  let(:elasticsearch_url) { ["https://localhost:9898"] }
  let(:elasticsearch_username) { "elastictest" }
  let(:elasticsearch_password) { "testchangeme" }
  let(:expected_url) { elasticsearch_url }
  let(:expected_username) { elasticsearch_username }
  let(:expected_password) { elasticsearch_password }
  let(:extension) {  LogStash::MonitoringExtension.new }
  let(:system_settings) { LogStash::Runner::SYSTEM_SETTINGS.clone }

  before :each do
    extension.additionals_settings(system_settings)
    apply_settings(settings, system_settings)
  end

  describe "es_options_from_settings" do
    context "with implicit username" do
      let(:settings) do
        {
          "xpack.monitoring.enabled" => true,
          "xpack.monitoring.elasticsearch.hosts" => elasticsearch_url,
        }
      end

      it "ignores the implicit default username when no password is set" do
        # when no explicit password is set then the default/implicit username should be ignored
        es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
        expect(es_options).to_not include("user")
        expect(es_options).to_not include("password")
      end

      context "with cloud_auth" do
        let(:cloud_username) { 'elastic' }
        let(:cloud_password) { 'passw0rd'}
        let(:cloud_auth) { "#{cloud_username}:#{cloud_password}" }

        let(:settings) do
          super().merge(
            "xpack.monitoring.elasticsearch.cloud_auth" => cloud_auth,
          )
        end

        it "silently ignores the default username" do
          es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
          expect(es_options).to include("cloud_auth")
          expect(es_options).to_not include("user")
        end
      end

      context "with api_key" do
        let(:settings) do
          super().merge(
            "xpack.monitoring.elasticsearch.api_key" => 'foo:bar'
          )
        end

        it "silently ignores the default username" do
          es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
          expect(es_options).to include("api_key")
          expect(es_options).to_not include("user")
        end

        context "and explicit password" do
          let(:settings) do
            super().merge(
              "xpack.monitoring.elasticsearch.password" => elasticsearch_password
            )
          end

          it "fails for multiple authentications" do
            expect {
              test_class.es_options_from_settings_or_modules('monitoring', system_settings)
            }.to raise_error(ArgumentError, /Multiple authentication options are specified/)
          end
        end
      end
    end

    context "with explicit username" do
      let(:settings) do
        {
          "xpack.monitoring.enabled" => true,
          "xpack.monitoring.elasticsearch.hosts" => elasticsearch_url,
          "xpack.monitoring.elasticsearch.username" => "foo",
        }
      end

      it "fails without password" do
        expect {
          test_class.es_options_from_settings_or_modules('monitoring', system_settings)
        }.to raise_error(ArgumentError, /password must also be set/)
      end

      context "with cloud_auth" do
        let(:settings) do
          super().merge(
            "xpack.monitoring.elasticsearch.password" => "bar",
            "xpack.monitoring.elasticsearch.cloud_auth" => "foo:bar",
          )
        end

        it "fails for multiple authentications" do
          expect {
            test_class.es_options_from_settings_or_modules('monitoring', system_settings)
          }.to raise_error(ArgumentError, /Both.*?cloud_auth.*?and.*?username.*?specified/)
        end
      end

      context "with api_key" do
        let(:settings) do
          super().merge(
            "xpack.monitoring.elasticsearch.password" => "bar",
            "xpack.monitoring.elasticsearch.api_key" => 'foo:bar'
          )
        end

        it "fails for multiple authentications" do
          expect {
            test_class.es_options_from_settings_or_modules('monitoring', system_settings)
          }.to raise_error(ArgumentError, /Multiple authentication options are specified/)
        end
      end
    end

    context "with username and password" do
      let(:settings) do
        {
          "xpack.monitoring.enabled" => true,
          "xpack.monitoring.elasticsearch.hosts" => elasticsearch_url,
          "xpack.monitoring.elasticsearch.username" => elasticsearch_username,
          "xpack.monitoring.elasticsearch.password" => elasticsearch_password,
        }
      end

      it_behaves_like 'elasticsearch options hash is populated without security'
      it_behaves_like 'elasticsearch options hash is populated with secure options'
    end

    context 'when cloud_id' do
      let(:cloud_name) { 'thebigone'}
      let(:cloud_domain) { 'elastic.co'}
      let(:cloud_id) { "monitoring:#{Base64.urlsafe_encode64("#{cloud_domain}$#{cloud_name}$ignored")}" }
      let(:expected_url) { ["https://#{cloud_name}.#{cloud_domain}:443"] }
      let(:settings) do
        {
          "xpack.monitoring.enabled" => true,
          "xpack.monitoring.elasticsearch.cloud_id" => cloud_id,
        }
      end

      context 'hosts also set' do
        let(:settings) do
          super().merge(
            "xpack.monitoring.elasticsearch.hosts" => 'https://localhost:9200'
          )
        end

        it "raises due invalid configuration" do
          expect {
            test_class.es_options_from_settings_or_modules('monitoring', system_settings)
           }.to raise_error(ArgumentError, /Both.*?cloud_id.*?and.*?hosts.*?specified/)
        end
      end

      context "when cloud_auth is set" do
        let(:cloud_username) { 'elastic' }
        let(:cloud_password) { 'passw0rd'}
        let(:cloud_auth) { "#{cloud_username}:#{cloud_password}" }
        let(:settings) do
          super().merge(
            "xpack.monitoring.elasticsearch.cloud_auth" => cloud_auth,
          )
        end

        it "creates the elasticsearch output options hash" do
          es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
          expect(es_options).to include("cloud_id" => cloud_id, "cloud_auth" => cloud_auth)
          expect(es_options.keys).to_not include("hosts")
          expect(es_options.keys).to_not include("username")
          expect(es_options.keys).to_not include("password")
        end

        context 'username also set' do
          let(:settings) do
            super().merge(
                "xpack.monitoring.elasticsearch.username" => 'elastic'
            )
          end

          it "raises for invalid configuration" do
            expect {
              test_class.es_options_from_settings_or_modules('monitoring', system_settings)
            }.to raise_error(ArgumentError, /Both.*?cloud_auth.*?and.*?username.*?specified/)
          end
        end

        context 'api_key also set' do
          let(:settings) do
            super().merge(
                "xpack.monitoring.elasticsearch.api_key" => 'foo:bar',
            )
          end

          it "raises for invalid configuration" do
            expect {
              test_class.es_options_from_settings_or_modules('monitoring', system_settings)
            }.to raise_error(ArgumentError, /Multiple authentication options are specified/)
          end
        end
      end

      context "when cloud_auth is not set" do
        it "does not use authentication and ignores the default username" do
          es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
          expect(es_options).to include("cloud_id")
          expect(es_options.keys).to_not include("hosts", "user", "password")
        end

        context 'username and password set' do
          let(:settings) do
            super().merge(
              "xpack.monitoring.elasticsearch.username" => 'foo',
              "xpack.monitoring.elasticsearch.password" => 'bar'
            )
          end

          it "creates the elasticsearch output options hash" do
            es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
            expect(es_options).to include("cloud_id", "user", "password")
            expect(es_options.keys).to_not include("hosts")
          end
        end

        context 'api_key set' do
          let(:settings) do
            super().merge(
              "xpack.monitoring.elasticsearch.api_key" => 'foo:bar'
            )
          end

          it "creates the elasticsearch output options hash" do
            es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
            expect(es_options).to include("cloud_id", "api_key")
            expect(es_options.keys).to_not include("hosts")
          end
        end
      end
    end

    context 'when api_key is set' do
      let(:api_key) { 'foo:bar'}
      let(:settings) do
        {
          "xpack.monitoring.enabled" => true,
          "xpack.monitoring.elasticsearch.hosts" => elasticsearch_url,
          "xpack.monitoring.elasticsearch.api_key" => api_key,
        }
      end

      it "creates the elasticsearch output options hash" do
        es_options = test_class.es_options_from_settings_or_modules('monitoring', system_settings)
        expect(es_options).to include("api_key" => api_key)
        expect(es_options.keys).to include("hosts")
      end

      context "with a non https host" do
        let(:elasticsearch_url) { ["https://host1", "http://host2"] }

        it "fails at options validation" do
          expect {
            test_class.es_options_from_settings_or_modules('monitoring', system_settings)
          }.to raise_error(ArgumentError, /api_key authentication requires SSL\/TLS/)
        end
      end
    end
  end

  describe 'es_options_from_settings_or_modules' do
    context 'when only settings are set' do
      let(:settings) do
        {
            "xpack.monitoring.enabled" => true,
            "xpack.monitoring.elasticsearch.hosts" => elasticsearch_url,
            "xpack.monitoring.elasticsearch.username" => elasticsearch_username,
            "xpack.monitoring.elasticsearch.password" => elasticsearch_password,
        }
      end

      it_behaves_like 'elasticsearch options hash is populated without security'
      it_behaves_like 'elasticsearch options hash is populated with secure options'
    end

    context 'with modules set' do
      let(:modules_es_url) { ["https://localhost:9898", "https://localhost:9999"]}
      let(:modules_es_username) { "modules_user"}
      let(:modules_es_password) { "correcthorsebatterystaple"}

      context 'when only modules cli are set' do
        let(:expected_url) { modules_es_url }
        let(:expected_username) { modules_es_username }
        let(:expected_password) { modules_es_password }
        let(:settings) { {"modules.cli" => [{ "name" => "hello",
                                                          'var.elasticsearch.hosts' => modules_es_url,
                                                          'var.elasticsearch.username' => modules_es_username,
                                                          'var.elasticsearch.password' => modules_es_password}]}
        }

        it_behaves_like 'elasticsearch options hash is populated without security'
      end

      context 'when only modules yaml are set' do
        let(:expected_url) { modules_es_url }
        let(:expected_username) { modules_es_username }
        let(:expected_password) { modules_es_password }
        let(:settings) { {"modules" => [{ "name" => "hello",
                                              'var.elasticsearch.hosts' => modules_es_url,
                                              'var.elasticsearch.username' => modules_es_username,
                                              'var.elasticsearch.password' => modules_es_password}]}
        }

        it_behaves_like 'elasticsearch options hash is populated without security'
      end

      context 'when cloud id and auth are set' do
        let(:cloud_name) { 'thebigone'}
        let(:cloud_domain) { 'elastic.co'}
        let(:base64_encoded) { Base64.urlsafe_encode64("#{cloud_domain}$#{cloud_name}$ignored")}
        let(:cloud_id) { "label:#{base64_encoded}" }
        let(:cloud_username) { 'cloudy' }
        let(:cloud_password) { 'cloud_password'}
        let(:expected_url) { ["https://#{cloud_name}.#{cloud_domain}:443"] }
        let(:expected_username) { cloud_username }
        let(:expected_password) { cloud_password }
        let(:settings) {
          {
              "cloud.id" => cloud_id,
              "cloud.auth" => "#{cloud_username}:#{cloud_password}",
              "modules" => [{ "name" => "hello",
                                          'var.elasticsearch.hosts' => modules_es_url,
                                          'var.elasticsearch.username' => modules_es_username,
                                          'var.elasticsearch.password' => modules_es_password}]}
        }

        it_behaves_like 'elasticsearch options hash is populated without security'
      end

      context 'when only modules cli and yaml are set' do
        let(:modules_cli_url) { ['cli:9200']}
        let(:modules_cli_username) { 'cli_user' }
        let(:modules_cli_password) { 'cli_password'}
        let(:expected_url) { modules_cli_url }
        let(:expected_username) { modules_cli_username }
        let(:expected_password) { modules_cli_password }
        let(:settings) { {"modules.cli" => [{ "name" => "hello",
                                              'var.elasticsearch.hosts' => modules_cli_url,
                                              'var.elasticsearch.username' => modules_cli_username,
                                              'var.elasticsearch.password' => modules_cli_password}],
                          "modules" => [{ "name" => "hello",
                                           'var.elasticsearch.hosts' => modules_es_url,
                                           'var.elasticsearch.username' => modules_es_username,
                                           'var.elasticsearch.password' => modules_es_password}]}
        }

        it_behaves_like 'elasticsearch options hash is populated without security'
      end

      context 'when everything is set' do
        let(:cloud_name) { 'thebigone'}
        let(:cloud_domain) { 'elastic.co'}
        let(:base64_encoded) { Base64.urlsafe_encode64("#{cloud_domain}$#{cloud_name}$ignored")}
        let(:cloud_id) { "label:#{base64_encoded}" }
        let(:cloud_username) { 'cloudy' }
        let(:cloud_password) { 'cloud_password'}
        let(:modules_cli_url) { ['cli:9200']}
        let(:modules_cli_username) { 'cli_user' }
        let(:modules_cli_password) { 'cli_password'}
        let(:settings) do
          { "modules" => [{ "name" => "hello",
                            'var.elasticsearch.hosts' => modules_es_url,
                            'var.elasticsearch.username' => modules_es_username,
                            'var.elasticsearch.password' => modules_es_password}],
            "modules.cli" => [{ "name" => "hello",
                                 'var.elasticsearch.hosts' => modules_cli_url,
                                 'var.elasticsearch.username' => modules_cli_username,
                                 'var.elasticsearch.password' => modules_cli_password}],
            "cloud.id" => cloud_id,
            "cloud.auth" => "#{cloud_username}:#{cloud_password}",
            "xpack.monitoring.enabled" => true,
            "xpack.monitoring.elasticsearch.hosts" => elasticsearch_url,
            "xpack.monitoring.elasticsearch.username" => elasticsearch_username,
            "xpack.monitoring.elasticsearch.password" => elasticsearch_password,
          }
        end

        it_behaves_like 'elasticsearch options hash is populated without security'
        it_behaves_like 'elasticsearch options hash is populated with secure options'
      end
    end
  end
end
