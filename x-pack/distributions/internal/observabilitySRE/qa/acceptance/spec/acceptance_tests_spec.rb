require 'net/http'
require 'uri'
require 'json'
require 'timeout'

describe "ObservabilitySRE FIPS container" do
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
  
  def wait_for_elasticsearch(max_retries = 120)
    retries = 0
    ready = false

    while !ready && retries < max_retries
      begin
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

  def docker_compose_invoke(subcommand, env={})
    env_str = env.map{ |k,v| "#{k.to_s.upcase}=#{Shellwords.escape(v)} "}.join
    work_dir = Pathname.new("#{__dir__}/../docker").cleanpath
    command = "#{env_str}docker-compose --project-directory=#{Shellwords.escape(work_dir)} #{subcommand}"
    system(command) or fail "Failed to invoke Docker Compose with command `#{command}`"
  end

  def docker_compose_up(env={}) = docker_compose_invoke("up --detach", env)

  def docker_compose_down(env={}) = docker_compose_invoke("down --volumes", env)

  context "when running LS to ES with FIPS-compliant configuration" do
    before(:all) do
      docker_compose_up
      wait_for_elasticsearch
    end

    after(:all) do
      docker_compose_down
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
  end

  context "when running LS to ES with non-FIPS compliant configuration" do
    before(:all) do
      docker_compose_up({"LOGSTASH_PIPELINE" => "logstash-to-elasticsearch-weak.conf"})
      wait_for_elasticsearch
    end

    after(:all) do
      docker_compose_down
    end

    it "prevents data flow when using TLSv1.1 which is not FIPS-compliant" do
        # Allow time for Logstash to attempt connections (and fail)
        sleep 15

        # Verify that no index has been created that would indicate successful data flow
        response = es_request("/_cat/indices?v")
        today_pattern = "logstash-weak-ssl-test-#{Time.now.strftime('%Y.%m.%d')}"
        expect(response.body).not_to include(today_pattern)

        # Check logs for the specific BouncyCastle FIPS error we expect
        logs = `docker logs fips_test_logstash 2>&1`

        # Verify the logs contain the FIPS-mode TLS protocol error
        expect(logs).to include("No usable protocols enabled")
        expect(logs).to include("IllegalStateException")
        expect(logs).to include("org.bouncycastle")
      end
  end

  context "When running Filebeat through LS to ES in a FIPS compliant configuration" do
    before(:all) do
      docker_compose_up({"LOGSTASH_PIPELINE" => "filebeat-to-ls-to-es.conf"})
      wait_for_elasticsearch
    end
  
    after(:all) do
      docker_compose_down
    end
  
    it "data flows from Filebeat through Logstash to Elasticsearch" do
      # Wait for index to appear, indicating data is flowing
      wait_until(timeout: 30, message: "Index filebeat-test not found") do
        response = es_request("/_cat/indices?v")
        response.code == "200" && response.body.include?("filebeat-test")
      end
      # Wait until specific data from filebeat/logstash mutate filters are observed
      query = { query: { match_all: {} } }.to_json
      result = nil
      wait_until(timeout: 30, message: "Index filebeat-test not found") do
        response = es_request("/filebeat-test-*/_search", query)
        result = JSON.parse(response.body)
        response.code == "200" && result["hits"]["total"]["value"] > 0
      end
      expect(result["hits"]["hits"].first["_source"]["tags"]).to include("filebeat")
    end
  end

  context "when running Filebeat through LS to ES with non-FIPS compliant configuration" do
    before(:all) do
      docker_compose_up({"LOGSTASH_PIPELINE" => "filebeat-to-ls-weak.conf"})
      wait_for_elasticsearch
    end

    after(:all) do
      docker_compose_down
    end

    it "prevents data flow when using TLSv1.1 which is not FIPS-compliant" do
        # Allow time for Logstash to attempt connections (and fail)
        sleep 15

        # Verify that no index has been created that would indicate successful data flow
        response = es_request("/_cat/indices?v")
        today_pattern = "filebeat-weak-ssl-test"
        expect(response.body).not_to include(today_pattern)

        # Check logs for the specific BouncyCastle FIPS error we expect
        logs = `docker logs fips_test_logstash 2>&1`

        # Verify the logs contain the FIPS-mode TLS protocol error
        expect(logs).to include("No usable protocols enabled")
        expect(logs).to include("IllegalStateException")
        expect(logs).to include("org.bouncycastle")
      end
  end
end