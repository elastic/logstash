#!/usr/bin/ruby

require "rubygems"
require "lib/config/base"
require "uri"
require "json"
require "ap"
require "logger"
require "httpclient"

module LogStash; module Net; module Clients
  class ElasticSearch
    def initialize(config_file)
      @config = LogStash::Config::BaseConfig.new(config_file)
      @http = HTTPClient.new
      @logger = Logger.new(STDERR)
    end

    def _get(params, what, path = "")
      path.gsub!(/\/+$/, "")
      uri = URI.escape("http://#{@config.elasticsearch_host}#{path}/_#{what}")
      @logger.info("URL for #{what}: #{uri}")
      @logger.info("Body: #{params.to_json}");
      # ElasticSearch uses "GET" with body, so we can't call .get() here.
      response = @http.request(:get, uri, query = nil, body = params.to_json)

      if response.status != 200
        ap JSON.parse(response.content)
        raise "Search failure (http code #{response.code})"
      end
      return JSON.parse(response.content)
    end

    def query(query, path = "")
      return ElasticSearch::SearchResults.new(_get(query, "search", path))
    end # def query

    def count(query, path = "")
      return _get(query, "count", path)["count"]
    end
  end

  class ElasticSearch::SearchResults
    attr_reader :hits
    attr_reader :results

    def initialize(data)
      @hits = data["hits"]["total"]
      @results = data["hits"]["hits"]
    end
  end # class Logstash::Net::Clients::ElasticSearch::SearchResults
end; end; end # module LogStash::Net::Clients
