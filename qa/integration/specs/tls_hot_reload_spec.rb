# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'
require_relative '../framework/helpers'
require_relative '../framework/cert_helpers'
require "logstash/devutils/rspec/spec_helper"
require "elasticsearch"
require "fileutils"
require "yaml"
require "stud/temporary"

describe "TLS hot-reload: SslFileTracker detects cert changes and reloads pipelines", :skip_fips do

  # Settings helpers

  def write_pipelines_yml(settings_dir, pipelines)
    IO.write(File.join(settings_dir, "pipelines.yml"), pipelines.to_yaml)
  end

  def spawn_with_reload(logstash_service, settings_dir, work_dir)
    IO.write(File.join(settings_dir, "logstash.yml"),
             { "ssl.reload.automatic" => true }.to_yaml)
    logstash_service.spawn_logstash(
      "--path.settings", settings_dir,
      "--config.reload.automatic", "true",
      "--config.reload.interval", "2s",
      "--path.data", File.join(work_dir, "data")
    )
  end

  # Reload helpers

  def wait_for_es_count(es_client, index_name, count: 1, retries: 15)
    Stud.try(retries.times, [StandardError]) do
      raise "Expected at least #{count} docs in #{index_name}" unless es_client.count(index: index_name)["count"].to_i >= count
    end
  rescue StandardError => e
    raise <<~MSG
      Timed out waiting for ES doc count after #{retries} retries.
      Expected: index=#{index_name}, count>=#{count}
    MSG
  end

  def wait_for_pipeline_reloads(logstash_service, *pipeline_ids, retries: 15, &block)
    raise ArgumentError, "block is required" unless block

    last_seen = {}
    Stud.try(retries.times, [StandardError, RSpec::Expectations::ExpectationNotMetError]) do
      pipeline_ids.each do |pid|
        pipeline = logstash_service.monitoring_api.pipeline_stats(pid.to_s)
        raise "Pipeline #{pid} not in stats" unless pipeline.is_a?(Hash)
        reloads = pipeline["reloads"]
        raise "Reloads not populated for pipeline #{pid}" unless reloads
        last_seen[pid] = {
          "reloads" => reloads,
          "pipeline" => pipeline
        }
        block.call(pid, reloads, pipeline)
      end
    end
  rescue StandardError, RSpec::Expectations::ExpectationNotMetError => e
    raise <<~MSG
      Timed out waiting for pipeline reloads after #{retries} retries.
      Pipelines: #{pipeline_ids.join(", ")}
      Last seen: #{last_seen.inspect}
    MSG
  end

  def wait_for_pipeline_reload_state(logstash_service, *pipeline_ids, successes:, failures:, retries: 15)
    wait_for_pipeline_reloads(logstash_service, *pipeline_ids, retries: retries) do |_pid, reloads, _pipeline|
      expect(reloads["successes"]).to eq(successes)
      expect(reloads["failures"]).to eq(failures)
    end
  end

  def wait_for_pipeline_reload_failures(logstash_service, *pipeline_ids, failures:, retries: 15)
    wait_for_pipeline_reloads(logstash_service, *pipeline_ids, retries: retries) do |_pid, reloads, _pipeline|
      expect(reloads["failures"]).to be >= failures
    end
  end

  def assert_pipeline_reload_state_stable(logstash_service, *pipeline_ids, successes:, failures:, retries: 5)
    wait_for_pipeline_reload_state(
      logstash_service,
      *pipeline_ids,
      successes: successes,
      failures: failures
    )

    retries.times do
      wait_for_pipeline_reload_state(
        logstash_service,
        *pipeline_ids,
        successes: successes,
        failures: failures,
        retries: 1
      )
      sleep 2
    end
  end

  # Suite setup: generate all cert variants once into a shared temp dir

  before(:all) do
    @cert_dir = Stud::Temporary.directory

    @ca_key, @ca_cert = generate_ca

    # server-v1 and server-v2: two distinct leaf certs (for rotation)
    @v1_key, @v1_cert = generate_leaf(@ca_key, @ca_cert)
    @v2_key, @v2_cert = generate_leaf(@ca_key, @ca_cert)

    # server-b: an independent leaf cert (for pipeline B, stays constant)
    @b_key, @b_cert = generate_leaf(@ca_key, @ca_cert)

    # es-ca-v1 and es-ca-v2: two independent self-signed CAs (for ES output)
    @es_ca_v1_key, @es_ca_v1_cert = generate_ca
    @es_ca_v2_key, @es_ca_v2_cert = generate_ca

    write_cert_pair(@cert_dir, "server-v1", @v1_key, @v1_cert)
    write_cert_pair(@cert_dir, "server-v2", @v2_key, @v2_cert)
    write_cert_pair(@cert_dir, "server-b",  @b_key,  @b_cert)

    # ES server cert signed by es-ca-v1, used by the elasticsearch_tls service
    es_server_key, es_server_cert = generate_leaf(@es_ca_v1_key, @es_ca_v1_cert)
    write_cert_pair(@cert_dir, "es-server", es_server_key, es_server_cert)
    File.write(File.join(@cert_dir, "es-ca.crt"), @es_ca_v1_cert.to_pem)

    # Set env vars before Fixture.new so elasticsearch_tls_setup.sh can read them
    ENV["ES_TLS_CERT"] = File.join(@cert_dir, "es-server.crt")
    ENV["ES_TLS_KEY"]  = File.join(@cert_dir, "es-server.key")
    ENV["ES_TLS_CA"]   = File.join(@cert_dir, "es-ca.crt")

    @fixture = Fixture.new(__FILE__)
  end

  after(:all) do
    @fixture.teardown
    ENV.delete("ES_TLS_CERT")
    ENV.delete("ES_TLS_KEY")
    ENV.delete("ES_TLS_CA")
    FileUtils.rm_rf(@cert_dir) if @cert_dir && Dir.exist?(@cert_dir)
  end

  let(:logstash_service) { @fixture.get_service("logstash") }
  let(:settings_dir)     { Stud::Temporary.directory }
  let(:work_dir)         { Stud::Temporary.directory }

  after(:each) { logstash_service.teardown }

  context "regular file cert rotation triggers exactly one reload" do
    let(:beats_port) { random_port }

    it "reloads once when cert is rotated, then stays stable" do
      crt = File.join(work_dir, "server.crt")
      key = File.join(work_dir, "server.key")
      FileUtils.cp(File.join(@cert_dir, "server-v1.crt"), crt)
      FileUtils.cp(File.join(@cert_dir, "server-v1.key"), key)

      write_pipelines_yml(settings_dir, [{
        "pipeline.id"   => "main",
        "config.string" => <<~CFG
          input  { beats { port => #{beats_port} ssl_enabled => true ssl_certificate => "#{crt}" ssl_key => "#{key}" } }
          output { null {} }
        CFG
      }])

      spawn_with_reload(logstash_service, settings_dir, work_dir)
      logstash_service.wait_for_rest_api

      wait_for_pipeline_reload_state(logstash_service, "main", successes: 0, failures: 0)

      FileUtils.cp(File.join(@cert_dir, "server-v2.crt"), crt)
      FileUtils.cp(File.join(@cert_dir, "server-v2.key"), key)

      # Wait several converge cycles and verify no second reload
      assert_pipeline_reload_state_stable(logstash_service, "main", successes: 1, failures: 0)
    end
  end

  context "symlink cert rotation triggers reload via mtime poll" do
    let(:beats_port) { random_port }

    it "detects symlink target change and reloads" do
      v1_crt = File.join(work_dir, "server-v1.crt")
      v2_crt = File.join(work_dir, "server-v2.crt")
      key_path = File.join(work_dir, "server.key")
      symlink  = File.join(work_dir, "server.crt")

      FileUtils.cp(File.join(@cert_dir, "server-v1.crt"), v1_crt)
      FileUtils.cp(File.join(@cert_dir, "server-v1.key"), key_path)
      FileUtils.cp(File.join(@cert_dir, "server-v2.crt"), v2_crt)
      # Ensure v2_crt has a strictly later mtime than v1_crt so the symlink
      # poll detects the target switch as a stamp change.
      sleep 1
      FileUtils.touch(v2_crt)
      File.symlink(v1_crt, symlink)

      write_pipelines_yml(settings_dir, [{
        "pipeline.id"   => "main",
        "config.string" => <<~CFG
          input  { beats { port => #{beats_port} ssl_enabled => true ssl_certificate => "#{symlink}" ssl_key => "#{key_path}" } }
          output { null {} }
        CFG
      }])

      spawn_with_reload(logstash_service, settings_dir, work_dir)
      logstash_service.wait_for_rest_api
      wait_for_pipeline_reload_state(logstash_service, "main", successes: 0, failures: 0)

      # Atomic symlink swap: point symlink at v2
      tmp_link = "#{symlink}.tmp"
      File.symlink(v2_crt, tmp_link)
      File.rename(tmp_link, symlink)

      wait_for_pipeline_reload_state(logstash_service, "main", successes: 1, failures: 0)
    end
  end

  context "rotating one pipeline cert does not reload the other" do
    let(:port_a) { random_port }
    let(:port_b) { random_port }

    it "reloads only the affected pipeline" do
      a_crt = File.join(work_dir, "a.crt")
      a_key = File.join(work_dir, "a.key")
      b_crt = File.join(work_dir, "b.crt")
      b_key = File.join(work_dir, "b.key")

      FileUtils.cp(File.join(@cert_dir, "server-v1.crt"), a_crt)
      FileUtils.cp(File.join(@cert_dir, "server-v1.key"), a_key)
      FileUtils.cp(File.join(@cert_dir, "server-b.crt"),  b_crt)
      FileUtils.cp(File.join(@cert_dir, "server-b.key"),  b_key)

      write_pipelines_yml(settings_dir, [
        {
          "pipeline.id"   => "beats-a",
          "config.string" => <<~CFG
            input  { beats { port => #{port_a} ssl_enabled => true ssl_certificate => "#{a_crt}" ssl_key => "#{a_key}" } }
            output { null {} }
          CFG
        },
        {
          "pipeline.id"   => "beats-b",
          "config.string" => <<~CFG
            input  { beats { port => #{port_b} ssl_enabled => true ssl_certificate => "#{b_crt}" ssl_key => "#{b_key}" } }
            output { null {} }
          CFG
        }
      ])

      spawn_with_reload(logstash_service, settings_dir, work_dir)
      logstash_service.wait_for_rest_api
      wait_for_pipeline_reload_state(logstash_service, "beats-a", successes: 0, failures: 0)

      FileUtils.cp(File.join(@cert_dir, "server-v2.crt"), a_crt)
      FileUtils.cp(File.join(@cert_dir, "server-v2.key"), a_key)

      wait_for_pipeline_reload_state(logstash_service, "beats-a", successes: 1, failures: 0)

      b_stats = logstash_service.monitoring_api.pipeline_stats("beats-b")["reloads"]
      expect(b_stats["successes"]).to eq(0)
      expect(b_stats["failures"]).to eq(0)
    end
  end

  context "shared cert rotation reloads both pipelines" do
    let(:port_a) { random_port }
    let(:port_b) { random_port }

    it "triggers reload on every pipeline referencing the rotated cert" do
      shared_crt = File.join(work_dir, "shared.crt")
      shared_key = File.join(work_dir, "shared.key")
      FileUtils.cp(File.join(@cert_dir, "server-v1.crt"), shared_crt)
      FileUtils.cp(File.join(@cert_dir, "server-v1.key"), shared_key)

      write_pipelines_yml(settings_dir, [
        {
          "pipeline.id"   => "beats-a",
          "config.string" => <<~CFG
            input  { beats { port => #{port_a} ssl_enabled => true ssl_certificate => "#{shared_crt}" ssl_key => "#{shared_key}" ssl_supported_protocols => ["TLSv1.2","TLSv1.3"] } }
            output { null {} }
          CFG
        },
        {
          "pipeline.id"   => "beats-b",
          "config.string" => <<~CFG
            input  { beats { port => #{port_b} ssl_enabled => true ssl_certificate => "#{shared_crt}" ssl_key => "#{shared_key}" ssl_supported_protocols => ["TLSv1.2","TLSv1.3"] } }
            output { null {} }
          CFG
        }
      ])

      spawn_with_reload(logstash_service, settings_dir, work_dir)
      logstash_service.wait_for_rest_api

      wait_for_pipeline_reload_state(logstash_service, "beats-a", "beats-b", successes: 0, failures: 0)

      FileUtils.cp(File.join(@cert_dir, "server-v2.crt"), shared_crt)
      FileUtils.cp(File.join(@cert_dir, "server-v2.key"), shared_key)

      wait_for_pipeline_reload_state(logstash_service, "beats-a", "beats-b", successes: 1, failures: 0)
    end
  end

  context "ES output truststore rotation with real Elasticsearch" do
    let(:truststore_password) { "changeit" }

    def es_client
      @fixture.get_service("elasticsearch_tls").get_client
    end

    it "detects truststore change, reloads, and continues sending events to ES" do
      index_name   = "tls-reload-truststore-test"
      ts_path      = File.join(work_dir, "es-truststore.p12")
      create_truststore(@es_ca_v1_cert, ts_path, truststore_password)

      write_pipelines_yml(settings_dir, [{
        "pipeline.id"   => "main",
        "config.string" => <<~CFG
          input  { generator { count => 0 } }
          output {
            elasticsearch {
              hosts => ["https://localhost:9200"]
              ssl_enabled => true
              ssl_truststore_path => "#{ts_path}"
              ssl_truststore_type => "pkcs12"
              ssl_truststore_password => "#{truststore_password}"
              user => "esadmin"
              password => "esadmin123"
              index => "#{index_name}"
            }
          }
        CFG
      }])

      spawn_with_reload(logstash_service, settings_dir, work_dir)
      logstash_service.wait_for_rest_api
      wait_for_es_count(es_client, index_name)

      # Rotate: add v2 CA to the truststore so content changes (triggers SslFileTracker).
      # ES server cert is still signed by v1, so Logstash stays connected after reload.
      create_truststore([@es_ca_v1_cert, @es_ca_v2_cert], ts_path, truststore_password)

      wait_for_pipeline_reload_state(logstash_service, "main", successes: 1, failures: 0)
      count_before = es_client.count(index: index_name)["count"].to_i
      wait_for_es_count(es_client, index_name, count: count_before + 1)
    end
  end

  context "ES output CA cert rotation with real Elasticsearch" do
    def es_client
      @fixture.get_service("elasticsearch_tls").get_client
    end

    it "detects CA cert change on the output side, reloads, and still sends events to ES" do
      index_name = "tls-reload-test"
      ls_ca_file = File.join(work_dir, "es-ca.crt")
      File.write(ls_ca_file, @es_ca_v1_cert.to_pem)

      write_pipelines_yml(settings_dir, [{
        "pipeline.id"   => "main",
        "config.string" => <<~CFG
          input  { generator { count => 0 } }
          output {
            elasticsearch {
              hosts => ["https://localhost:9200"]
              ssl_enabled => true
              ssl_certificate_authorities => ["#{ls_ca_file}"]
              user => "esadmin"
              password => "esadmin123"
              index => "#{index_name}"
            }
          }
        CFG
      }])

      # start logstash
      spawn_with_reload(logstash_service, settings_dir, work_dir)
      logstash_service.wait_for_rest_api
      wait_for_es_count(es_client, index_name)

      # update cert file
      File.open(ls_ca_file, "a") { |f| f.write(@es_ca_v2_cert.to_pem) }

      # confirm ingestion succeeds
      wait_for_pipeline_reload_state(logstash_service, "main", successes: 1, failures: 0)
      count_before = es_client.count(index: index_name)["count"].to_i
      wait_for_es_count(es_client, index_name, count: count_before + 1)
    end

    it "reloads on invalid CA cert rotation, then recovers after a valid CA rotation" do
      index_name = "tls-reload-neg-test"
      ls_ca_file = File.join(work_dir, "es-ca-neg.crt")
      File.write(ls_ca_file, @es_ca_v1_cert.to_pem)

      write_pipelines_yml(settings_dir, [{
        "pipeline.id"   => "main",
        "config.string" => <<~CFG
          input  { generator { count => 0 } }
          output {
            elasticsearch {
              hosts => ["https://localhost:9200"]
              ssl_enabled => true
              ssl_certificate_authorities => ["#{ls_ca_file}"]
              user => "esadmin"
              password => "esadmin123"
              index => "#{index_name}"
            }
          }
        CFG
      }])

      # start logstash
      spawn_with_reload(logstash_service, settings_dir, work_dir)
      logstash_service.wait_for_rest_api
      wait_for_es_count(es_client, index_name)
      initial_count = es_client.count(index: index_name)["count"].to_i

      # update cert file with invalid content
      File.write(ls_ca_file, "not a valid certificate")

      # invalid CA reload should fail and stop ingestion
      wait_for_pipeline_reload_failures(logstash_service, "main", failures: 1)
      count_after_invalid_rotation = es_client.count(index: index_name)["count"].to_i
      expect(count_after_invalid_rotation).to be >= initial_count
      sleep 15
      expect(es_client.count(index: index_name)["count"].to_i).to eq(count_after_invalid_rotation)

      # restoring a valid CA should trigger another reload and ingestion should recover
      File.write(ls_ca_file, @es_ca_v1_cert.to_pem)

      wait_for_pipeline_reload_state(logstash_service, "main", successes: 1, failures: 1)
      wait_for_es_count(es_client, index_name, count: count_after_invalid_rotation + 1)
    end
  end
end
