require_relative '../../spec/shared_helpers.rb'

describe "ObservabilitySRE FIPS container" do
  include SharedHelpers

  context "when running LS to ES with FIPS-compliant configuration" do
    before(:all) do
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_up({}, work_dir)
      wait_for_elasticsearch
    end

    after(:all) do
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_down({}, work_dir)
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
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_up({"LOGSTASH_PIPELINE" => "logstash-to-elasticsearch-weak.conf"}, work_dir)
      wait_for_elasticsearch
    end

    after(:all) do
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_down({}, work_dir)
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
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_up({"LOGSTASH_PIPELINE" => "filebeat-to-ls-to-es.conf"}, work_dir)
      wait_for_elasticsearch
    end

    after(:all) do
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_down({}, work_dir)
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
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_up({"LOGSTASH_PIPELINE" => "filebeat-to-ls-weak.conf"}, work_dir)
      wait_for_elasticsearch
    end

    after(:all) do
      work_dir = File.expand_path("../docker", __dir__)
      docker_compose_down({}, work_dir)
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