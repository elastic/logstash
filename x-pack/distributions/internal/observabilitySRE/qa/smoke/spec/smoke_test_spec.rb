require_relative '../../spec/shared_helpers.rb'

describe "Observability SRE smoke tests" do
  include SharedHelpers

  before(:all) do
    @es_url = "https://localhost:9200"
    @es_user = "elastic"
    @es_password = "changeme"
    
    work_dir = File.expand_path("../docker", __dir__)
    docker_compose_up({}, work_dir)
    wait_for_elasticsearch(120, require_documents: true, index_pattern: "logs-*")
  end

  after(:all) do
    work_dir = File.expand_path("../docker", __dir__)
    docker_compose_down({}, work_dir)
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

    it "ingests logs from Filebeat" do
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

    it "applies JSON filter" do
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

    it "applies date filter" do
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

    it "tags old events" do
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

    it "drops DEBUG logs" do
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

    it "adds fingerprints to logs" do
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

    it "adds environment field via mutate" do
      response = es_request("/logs-*/_search?pretty", query)
      data = JSON.parse(response.body)

      expect(data["hits"]["total"]["value"]).to be > 0
      data["hits"]["hits"].each do |hit|
        expect(hit["_source"]["environment"]).to eq("test")
      end
    end
  end
end