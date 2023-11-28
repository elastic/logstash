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
require "stud/temporary"
require "stud/try"
require "rspec/wait"
require "yaml"
require "fileutils"

describe "Beat Input" do
  before(:all) do
    @fixture = Fixture.new(__FILE__)
  end

  after :each do
    logstash_service.teardown
    filebeat_service.stop
  end

  before :each do
    FileUtils.mkdir_p(File.dirname(registry_file))
  end

  let(:max_retry) { 120 }
  let(:registry_file) { File.join(Stud::Temporary.pathname, "registry") }
  let(:logstash_service) { @fixture.get_service("logstash") }
  let(:filebeat_service) { @fixture.get_service("filebeat") }
  let(:log_path) do
    tmp_path = Stud::Temporary.file.path #get around ignore older completely
    source = File.expand_path(@fixture.input)
    FileUtils.cp(source, tmp_path)
    tmp_path
  end
  let(:number_of_events) do
    File.open(log_path, "r").readlines.size
  end

  shared_examples "send events" do
    let(:filebeat_config_path) do
      file = Stud::Temporary.file
      file.write(YAML.dump(filebeat_config))
      file.close
      file.path
    end

    it "successfully send events" do
      logstash_service.start_background(logstash_config)
      process = filebeat_service.run(filebeat_config_path)

      # It can take some delay for filebeat to connect to logstash and start sending data.
      # Its possible that logstash isn't completely initialized here, we can get "Connection Refused"
      begin
        sleep(1) while (result = logstash_service.monitoring_api.event_stats).nil?
      rescue
        sleep(1)
        retry
      end

      Stud.try(max_retry.times, RSpec::Expectations::ExpectationNotMetError) do
         result = logstash_service.monitoring_api.event_stats
         expect(result["in"]).to eq(number_of_events)
      end
    end
  end

  context "Without TLS" do
    let(:logstash_config) { @fixture.config("without_tls") }
    let(:filebeat_config) do
      {
        "filebeat" => {
          "inputs" => [{ "paths" => [log_path], "input_type" => "log" }],
          "registry.path" => registry_file,
          "scan_frequency" => "1s"
        },
        "output" => {
          "logstash" => { "hosts" => ["localhost:5044"] }
        },
        "logging" => { "level" => "debug" }
      }
    end

    include_examples "send events"
  end

  context "With TLS" do
    let(:certificate_directory) { File.expand_path(File.join(File.dirname(__FILE__), "..", "fixtures", "certificates")) }
    let(:certificate) { File.join(certificate_directory, "certificate.crt") }
    let(:ssl_key) { File.join(certificate_directory, "certificate.key") }
    let(:certificate_authorities) { [certificate] }

    context "Server auth" do
      let(:logstash_config) { @fixture.config("tls_server_auth", { :ssl_certificate => certificate, :ssl_key => ssl_key}) }
      let(:filebeat_config) do
        {
          "filebeat" => {
            "inputs" => [{ "paths" => [log_path], "input_type" => "log" }],
            "registry.path" => registry_file,
            "scan_frequency" => "1s"
          },
          "output" => {
            "logstash" => {
              "hosts" => ["localhost:5044"],
              "tls" => {
                "certificate_authorities" => certificate_authorities
              },
              "ssl" => {
                "certificate_authorities" => certificate_authorities
              }
            }
          },
          "logging" => { "level" => "debug" }
        }
      end

      include_examples "send events"
    end

    context "Mutual auth" do
      let(:logstash_config) { @fixture.config("tls_mutual_auth", { :ssl_certificate => certificate, :ssl_key => ssl_key}) }
      let(:filebeat_config) do
        {
          "filebeat" => {
            "inputs" => [{ "paths" => [log_path], "input_type" => "log" }],
            "registry.path" => registry_file,
            "scan_frequency" => "1s"
          },
          "output" => {
            "logstash" => {
              "hosts" => ["localhost:5044"],
              "tls" => {
                "certificate_authorities" => certificate_authorities,
                "certificate" => certificate,
                "certificate_key" => ssl_key
              },
              "ssl" => {
                "certificate_authorities" => certificate_authorities,
                "certificate" => certificate,
                "key" => ssl_key
              }
            }
          },
          "logging" => { "level" => "debug" }
        }
      end

      include_examples "send events"
    end
  end
end
