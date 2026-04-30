# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative "../spec_helper"
require "stud/temporary"
require "net/http"
require "json"

describe "TLS hot-reload: CPM (ElasticsearchSource) detects cert changes and rebuilds clients", :skip_fips do
  PIPELINE_ID = "cpm-tls-hot-reload"

  before(:all) do
    # generate certs
    @cert_dir = Stud::Temporary.directory

    @ca_key,  @ca_cert  = generate_ca
    @ca2_key, @ca2_cert = generate_ca

    es_key, es_cert = generate_leaf(@ca_key, @ca_cert)

    # add CPM pipeline to ES
    @elasticsearch_service = elasticsearch_with_tls(es_cert.to_pem, es_key.to_pem, @ca_cert.to_pem)

    tls_client = elasticsearch_client_tls
    begin
      tls_client.perform_request(:delete, "_logstash/pipeline/#{PIPELINE_ID}")
    rescue Elastic::Transport::Transport::Errors::NotFound
    end
    tls_client.perform_request(:put, "_logstash/pipeline/#{PIPELINE_ID}", {},
      { pipeline: "input { generator { count => 0 } } output { null {} }",
        username: "log.stash",
        pipeline_metadata: { version: "1" },
        pipeline_settings: { "pipeline.batch.delay": "50" },
        last_modified: Time.now.utc.iso8601 })

    # write ca.crt
    @ca_file = File.join(@cert_dir, "ca.crt")
    File.write(@ca_file, @ca_cert.to_pem)

    # start Logstash with CPM
    # log.level: debug because the rebuild line in ElasticsearchClientHolder logs at DEBUG.
    @logstash_service = logstash_with_empty_default("bin/logstash -w 1", {
      :settings => {
        "log.level"                                                 => "debug",
        "ssl.reload.automatic"                                      => true,
        "xpack.management.enabled"                                  => true,
        "xpack.management.pipeline.id"                              => [PIPELINE_ID],
        "xpack.management.elasticsearch.hosts"                      => ["https://localhost:9200"],
        "xpack.management.elasticsearch.username"                   => "elastic",
        "xpack.management.elasticsearch.password"                   => elastic_password,
        "xpack.management.elasticsearch.ssl.certificate_authority"  => @ca_file,
        "xpack.management.logstash.poll_interval"                   => "2s",
        "xpack.monitoring.enabled"                                   => false
      },
      :belzebuth => {
        :wait_condition => /Pipelines running/,
        :timeout        => 60
      }
    })
  end

  after(:all) do
    cleanup_tls_certs_from_es_config
    elasticsearch_client_tls.perform_request(:delete, "_logstash/pipeline/#{PIPELINE_ID}") rescue nil
    @logstash_service&.stop
    @elasticsearch_service&.stop
  end

  context "CA cert file changes" do
    # Appending a second CA to the bundle changes the file's content; SHA-256 changes.
    # The original CA stays in the bundle so ES connectivity survives throughout.
    # SslFileTracker detects the change and both the ElasticsearchSource client
    # and the LicenseReader client are rebuilt independently.
    it "detects the change, rebuilds both clients, and the new connection remains functional" do
      Stud.try(15.times, [StandardError]) do
        stats = logstash_pipeline_stats(PIPELINE_ID)
        raise "CPM pipeline not running yet" unless stats
      end

      # No reloads before cert rotation
      stats = logstash_pipeline_stats(PIPELINE_ID)
      expect(stats["reloads"]["successes"]).to eq(0)
      expect(stats["reloads"]["failures"]).to eq(0)

      # Rotate: append second CA. Content changes; connection still works.
      File.open(@ca_file, "a") { |f| f.write(@ca2_cert.to_pem) }

      # Two rebuild events: the CPM ES client (driven by Agent's reload tick)
      # and the LicenseReader client (driven by LicenseManager's scheduler tick).
      wait_for_log_count(/rebuilt elasticsearch client.*on certificate change/, 2)

      # Push a pipeline update so CPM must fetch via the new client
      elasticsearch_client_tls.perform_request(:put, "_logstash/pipeline/#{PIPELINE_ID}", {},
        { pipeline: "input { generator { count => 0 } } output { sink {} }",
          username: "log.stash",
          pipeline_metadata: { version: "2" },
          pipeline_settings: { "pipeline.batch.delay": "50" },
          last_modified: Time.now.utc.iso8601 })

      # Wait for CPM to fetch and apply the update to prove new client can connect
      Stud.try(30.times, [StandardError]) do
        stats = logstash_pipeline_stats(PIPELINE_ID)
        raise "Pipeline not reloaded yet" unless stats && stats["reloads"]["successes"] == 1
      end

      expect(@logstash_service.stdout_lines.join("\n")).not_to match(/\[ERROR\]/)
    end
  end

  private

  def wait_for_log_count(pattern, count, tries: 30)
    Stud.try(tries.times, [StandardError]) do
      actual = @logstash_service.stdout_lines.join("\n").scan(pattern).size
      raise "Log pattern #{pattern.inspect} seen #{actual} times, want #{count}" unless actual == count
    end
  end

  def logstash_pipeline_stats(pipeline_id)
    uri  = URI("http://localhost:9600/_node/stats/pipelines/#{pipeline_id}")
    resp = Net::HTTP.get_response(uri)
    return nil unless resp.code == "200"
    JSON.parse(resp.body).dig("pipelines", pipeline_id)
  rescue
    nil
  end
end
