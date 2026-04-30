# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative "../spec_helper"
require "stud/temporary"

# LicenseManager runs fetch_license every 30 seconds via a background scheduler.
# With config.reload.automatic: true, Runner creates the SslFileTracker and passes
# it into InternalPipelineSource, which attaches it to the LicenseManager. The
# scheduler then notices cert changes and rebuilds the client on its next tick.
# With config.reload.automatic: false (the default), no tracker is created, so
# cert changes are silently ignored.
#
# Note: -e (config.string) cannot be combined with an explicitly-set
# config.reload.automatic, because config_reload_automatic? checks set?
# (not the value). Both tests use -f to avoid this constraint.

describe "Monitoring TLS hot-reload", :skip_fips do
  PIPELINE_CONF = "input { generator { count => 0 } } output { null {} }"

  def setup_monitoring_logstash(extra_settings = {})
    @cert_dir = Stud::Temporary.directory

    @ca_key,  @ca_cert  = generate_ca
    @ca2_key, @ca2_cert = generate_ca

    es_key, es_cert = generate_leaf(@ca_key, @ca_cert)
    @elasticsearch_service = elasticsearch_with_tls(es_cert.to_pem, es_key.to_pem, @ca_cert.to_pem)

    @ca_file = File.join(@cert_dir, "ca.crt")
    File.write(@ca_file, @ca_cert.to_pem)

    config_file = File.join(@cert_dir, "pipeline.conf")
    File.write(config_file, PIPELINE_CONF)

    # log.level: debug because the rebuild line in ElasticsearchClientHolder logs at DEBUG.
    base_settings = {
      "log.level"                                                 => "debug",
      "xpack.monitoring.enabled"                                  => true,
      "xpack.monitoring.allow_legacy_collection"                  => true,
      "xpack.monitoring.elasticsearch.hosts"                      => ["https://localhost:9200"],
      "xpack.monitoring.elasticsearch.username"                   => "elastic",
      "xpack.monitoring.elasticsearch.password"                   => elastic_password,
      "xpack.monitoring.elasticsearch.ssl.certificate_authority"  => @ca_file
    }

    @logstash_service = logstash_with_empty_default("bin/logstash -f #{config_file} -w 1", {
      :settings => base_settings.merge(extra_settings),
      :belzebuth => {
        :wait_condition => /Pipelines running/,
        :timeout        => 60
      }
    })
  end

  def teardown_monitoring_logstash
    cleanup_tls_certs_from_es_config
    @logstash_service&.stop
    @elasticsearch_service&.stop
  end

  def wait_for_log_line(pattern, tries: 30)
    Stud.try(tries.times, [StandardError]) do
      unless @logstash_service.stdout_lines.join("\n") =~ pattern
        raise "Log pattern not yet visible: #{pattern.inspect}"
      end
    end
  end

  context "config.reload.automatic: true" do
    before(:all) do
      setup_monitoring_logstash(
        "config.reload.automatic" => true,
        "config.reload.interval"  => "2s",
        "ssl.reload.automatic" => true
      )
    end

    after(:all) { teardown_monitoring_logstash }

    it "cert rotation rebuilds the license reader client and monitoring continues" do
      # Wait for initial monitoring docs before rotation to confirm monitoring is active
      initial_count = Stud.try(15.times, [StandardError]) do
        elasticsearch_client_tls.indices.refresh(index: MONITORING_INDEXES)
        resp = elasticsearch_client_tls.count(index: MONITORING_INDEXES)
        raise "No monitoring docs yet" unless resp["count"] > 0
        resp["count"]
      end

      # Rotate: append second CA. Original CA stays so ES connectivity survives.
      File.open(@ca_file, "a") { |f| f.write(@ca2_cert.to_pem) }

      # LicenseManager scheduler fires every 30s
      wait_for_log_line(/rebuilt elasticsearch client.*on certificate change/)

      # Doc count must grow to prove the rebuilt client can still write monitoring data to ES
      Stud.try(15.times, [StandardError]) do
        elasticsearch_client_tls.indices.refresh(index: MONITORING_INDEXES)
        count = elasticsearch_client_tls.count(index: MONITORING_INDEXES)["count"]
        raise "Doc count not yet exceeded initial (#{count} <= #{initial_count})" unless count > initial_count
      end

      expect(@logstash_service.stdout_lines.join("\n")).not_to match(/\[ERROR\]/)
    end
  end

  context "config.reload.automatic: false" do
    before(:all) { setup_monitoring_logstash }

    after(:all) { teardown_monitoring_logstash }

    it "cert rotation is ignored and no error is raised" do
      initial_length = @logstash_service.stdout_lines.length

      # Rotate: append second CA.
      File.open(@ca_file, "a") { |f| f.write(@ca2_cert.to_pem) }

      # Wait longer than one LicenseManager scheduler cycle (30s) to confirm silence.
      sleep 35

      output_after_rotation = @logstash_service.stdout_lines[initial_length..].join("\n")
      expect(output_after_rotation).not_to match(/rebuilt elasticsearch client.*on certificate change/)
      expect(output_after_rotation).not_to match(/\[ERROR\]/)
    end
  end
end
