# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require_relative "../spec_helper"

describe "Monitoring internal collector documents" do
  before :all do
    @elasticsearch_service = elasticsearch

    cleanup_elasticsearch

    # this is tcp input useful to keep main pipeline alive
    @config = "input { tcp { port => 6000 } } output { null {} }"
  end

  let(:max_retry) { 10 }
  let(:schemas_path) { File.join(File.dirname(__FILE__), "..", "..", "..", "spec", "monitoring", "schemas") }
  let(:retryable_errors) do
    [NoMethodError,
     RSpec::Expectations::ExpectationNotMetError,
     Elasticsearch::Transport::Transport::Errors::ServiceUnavailable,
     Elasticsearch::Transport::Transport::Errors::NotFound]
  end

  describe "metrics" do
    it "should be equal to with direct shipping" do
      @logstash_service = start_monitoring_logstash(@config)
      direct_shipping_document = retrieve_monitoring_document_from_es("logstash_stats")

      @logstash_service.stop unless @logstash_service.nil?

      cleanup_elasticsearch

      @logstash_service = start_monitoring_logstash(@config, "xpack")
      es_reporter_shaped_document = retrieve_monitoring_document_from_es("logstash_stats")

      @logstash_service.stop unless @logstash_service.nil?

      verify_same_structure(es_reporter_shaped_document, direct_shipping_document)
    end
  end

  describe "state" do
    it "should be equal to with direct shipping" do
      @logstash_service = start_monitoring_logstash(@config)
      direct_shipping_document = retrieve_monitoring_document_from_es("logstash_state")
      @logstash_service.stop unless @logstash_service.nil?

      cleanup_elasticsearch

      @logstash_service = start_monitoring_logstash(@config, "xpack")
      es_reporter_shaped_document = retrieve_monitoring_document_from_es("logstash_state")

      @logstash_service.stop unless @logstash_service.nil?

      verify_same_structure(es_reporter_shaped_document, direct_shipping_document)
    end
  end

  after :all do
    @elasticsearch_service.stop unless @elasticsearch_service.nil?
  end
end

def retrieve_monitoring_document_from_es(document_type)
  monitoring_document = nil

  Stud.try(max_retry.times, retryable_errors) do
    elasticsearch_client.indices.refresh
    api_response = elasticsearch_client.search :index => MONITORING_INDEXES, :body => {:query => {:term => {"type" => document_type}}}
    expect(api_response["hits"]["total"]["value"]).to be > 0
    api_response["hits"]["hits"].each do |full_document|
      monitoring_document = full_document["_source"]
    end
  end
  monitoring_document
end

def start_monitoring_logstash(config, prefix = "")
  if !prefix.nil? && !prefix.empty?
    mon_prefix = prefix + "."
  else
    mon_prefix = ""
  end
  logstash_with_empty_default("bin/logstash -e '#{config}' -w 1", {
    :settings => {
      "#{mon_prefix}monitoring.enabled" => true,
      "#{mon_prefix}monitoring.elasticsearch.hosts" => ["http://localhost:9200", "http://localhost:9200"],
      "#{mon_prefix}monitoring.collection.interval" => "1s",
      "#{mon_prefix}monitoring.elasticsearch.username" => "elastic",
      "#{mon_prefix}monitoring.elasticsearch.password" => elastic_password
    }, # will be saved in the logstash.yml
    :belzebuth => {
      :wait_condition => /Pipelines running/,
      :timeout => 5 * 60 # Fail safe, this mean something went wrong if we hit this before the wait_condition
    }
  })
end

def verify_same_structure(original, other, ignored_keys = /^source_node/)
  orig_keys = filter_ignored_and_make_set(flatten_keys(original), ignored_keys)
  other_keys = filter_ignored_and_make_set(flatten_keys(other), ignored_keys)
  expect(other_keys - orig_keys).to eq([])
  expect(orig_keys - other_keys).to eq([])
end

def filter_ignored_and_make_set(keys_list, ignored_keys)
  keys_list.sort.uniq.select { |k| !(k =~ ignored_keys) }
end

def flatten_keys(hash, prefix = "")
  flattened_keys = []
  hash.each do |k, v|
    if v.is_a? Hash
      flattened_keys += flatten_keys(v, k.to_s)
    else
      flattened_keys << (prefix + (prefix.empty? ? "" : ".") + k.to_s)
    end
  end
  flattened_keys
end
