require 'net/http'
require 'uri'
require 'json'
require 'timeout'

describe "ObservabilitySRE FIPS container running on FIPS vm" do
  
  before(:all) do
    # Start docker-compose and wait for ES
    system("cd #{__dir__}/../docker && docker-compose up -d") or fail "Failed to start Docker Compose environment"
    max_retries = 120
    retries = 0
    ready = false
    
    while !ready && retries < max_retries
      begin
        # Wait for elasticsearch to be ready
        response = es_request("/_cluster/health")
        if response.code == "200"
          health = JSON.parse(response.body)
          if ["green", "yellow"].include?(health["status"])
            ready = true
          end
        end
      rescue => e
        puts "Waiting for Elasticsearch: #{e.message}"
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
  
  after(:all) do
    # stop docker network
    system("cd #{__dir__}/../docker && docker-compose down -v")
  end
  
  it "data flows from Logstash to Elasticsearch using FIPS-approved SSL" do
    # Wait for index to appear, indicating data is flowing
    wait_until(timeout: 30, message: "Index logstash-fips-test not found") do
      response = es_request("/_cat/indices?v")
      response.code == "200" && response.body.include?("logstash-fips-test")
    end
    # Wait until specific data from logstash generator/mutate filters are observed
    query = { query: { match_all: {} } }.to_json
    result = nil
    wait_until(timeout: 30, message: "Index logstash-fips-test not found") do
        response = es_request("/logstash-fips-test-*/_search", query)
        result = JSON.parse(response.body)
        response.code == "200" && result["hits"]["total"]["value"] > 0
      end
    expect(result["hits"]["hits"].first["_source"]).to include("fips_test")
  end

  def wait_until(timeout: 30, interval: 1, message: nil)
    Timeout.timeout(timeout) do
      loop do
        break if yield
        sleep interval
      end
    end
  rescue Timeout::Error
    raise message || "Condition not met within #{timeout} seconds"
  end

  def es_request(path, body = nil)
    es_url = "https://localhost:9200"
    es_user = 'elastic'
    es_password = 'changeme'
    uri = URI.parse(es_url + path)
    http = Net::HTTP.new(uri.host, uri.port)
    http.use_ssl = true
    http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    
    request = body ? Net::HTTP::Post.new(uri.request_uri) : Net::HTTP::Get.new(uri.request_uri)
    request.basic_auth(es_user, es_password)
    request["Content-Type"] = "application/json"
    request.body = body if body
    
    http.request(request)
  end
end