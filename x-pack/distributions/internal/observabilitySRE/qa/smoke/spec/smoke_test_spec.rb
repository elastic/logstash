require 'json'
require 'net/http'
require 'uri'
require 'openssl'

describe "Observability SRE smoke tests" do
  before(:all) do
    @es_url = "https://localhost:9200"
    @es_user = "elastic"
    @es_password = "changeme"
    
    max_retries = 120
    retries = 0
    ready = false
    
    while !ready && retries < max_retries
      begin
        # Check cluster health first
        response = es_request("/_cluster/health")
        if response.code == "200"
          health = JSON.parse(response.body)
          if ["green", "yellow"].include?(health["status"])
            # Wait for logs-* index to be created and have documents
            logs_response = es_request("/logs-*/_count")
            if logs_response.code == "200"
              count_data = JSON.parse(logs_response.body)
              if count_data["count"] > 0
                ready = true
                puts "Found #{count_data["count"]} documents in logs index"
              else
                puts "Waiting for documents in logs index..."
              end
            end
          end
        end
      rescue => e
        puts "Waiting for Elasticsearch/Logstash: #{e.message}"
      ensure
        unless ready
          retries += 1
          sleep 1
          puts "Retry #{retries}/#{max_retries}"
        end
      end
    end
    
    raise "System not ready after #{max_retries} seconds" unless ready
  end
  def es_request(path, body = nil)
    uri = URI.parse(@es_url + path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    if body
      request = Net::HTTP::Post.new(uri.request_uri)
      request.body = body
    else
      request = Net::HTTP::Get.new(uri.request_uri)
    end
    
    request.basic_auth(@es_user, @es_password)
    request["Content-Type"] = "application/json"
    
    http.request(request)
  end
  
  context "Log ingestion" do
    let(:query) do
      JSON.generate({
        "size": 10,
        "query": {
          "prefix": {
            "message.keyword": "TEST-LOG"
          }
        }
      })
    end
    
    it "should ingest logs from Filebeat" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)
      
      expect(response.code).to eq("200")
      expect(data["hits"]["total"]["value"]).to be > 0
    end
  end
  
  context "JSON filter" do
    let(:query) do
      JSON.generate({
        "size": 5,
        "query": {
          "exists": {
            "field": "parsed_json"
          }
        }
      })
    end
    
    it "should apply JSON filter" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)
      
      expect(response.code).to eq("200")
      expect(data["hits"]["total"]["value"]).to be > 0
      
      hit = data["hits"]["hits"].first
      expect(hit["_source"]["parsed_json"]).to be_a(Hash)
    end
  end
  
  context "Date filter" do
    let(:query) do
      JSON.generate({
        "size": 10,
        "_source": ["message", "@timestamp", "timestamp"],
        "query": {
          "match_phrase": {
            "message": "timestamp"
          }
        }
      })
    end
    
    it "should apply date filter" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)
      
      # Find logs with timestamps in their content
      timestamp_logs = data["hits"]["hits"].select do |hit|
        hit["_source"]["message"] && hit["_source"]["message"].include?("timestamp=")
      end
      
      # Verify that the timestamp was extracted and used
      expect(timestamp_logs).not_to be_empty
      timestamp_logs.each do |log|
        if log["_source"]["timestamp"]
          timestamp_without_ms = log["_source"]["@timestamp"].gsub('.000Z', 'Z')
          expect(timestamp_without_ms).to eq(log["_source"]["timestamp"])
        end
      end
    end
  end
  
  context "Age filter" do
    let(:query) do
      JSON.generate({
        "size": 5,
        "_source": ["message", "@timestamp", "tags"],
        "query": {
          "match": {
            "tags": "old_event"
          }
        }
      })
    end
    
    it "should tag old events" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)
      
      expect(data["hits"]["total"]["value"]).to be > 0
      data["hits"]["hits"].each do |hit|
        expect(hit["_source"]["tags"]).to include("old_event")
      end
    end
  end
  
  context "Drop filter" do
    let(:query) do
      JSON.generate({
        "size": 5,
        "query": {
          "match_phrase": {
            "message": "DEBUG"
          }
        }
      })
    end
    
    it "should drop DEBUG logs" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)
      
      expect(data["hits"]["total"]["value"]).to eq(0)
    end
  end
  
  context "Fingerprint filter" do
    let(:query) do
      JSON.generate({
        "size": 5,
        "_source": ["message", "fingerprint"],
        "query": {
          "exists": {
            "field": "fingerprint"
          }
        }
      })
    end
    
    it "should add fingerprints to logs" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)
      
      expect(data["hits"]["total"]["value"]).to be > 0
      data["hits"]["hits"].each do |hit|
        expect(hit["_source"]["fingerprint"]).to be_a(String)
        expect(hit["_source"]["fingerprint"].length).to eq(32) # MD5 is 32 chars
      end
    end
  end
  
  context "Mutate filter" do
    let(:query) do
      JSON.generate({
        "size": 5,
        "_source": ["message", "environment"],
        "query": {
          "exists": {
            "field": "environment"
          }
        }
      })
    end
    
    it "should add environment field via mutate" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)
      
      expect(data["hits"]["total"]["value"]).to be > 0
      data["hits"]["hits"].each do |hit|
        expect(hit["_source"]["environment"]).to eq("test")
      end
    end
  end
end