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

require "logstash/webserver"
require_relative "../support/helpers"
require "socket"
require "spec_helper"
require "open-uri"
require "webmock/rspec"
require "faraday"
require "ostruct"

def block_ports(range)
  servers = []

  range.each do |port|
    begin
      server = TCPServer.new("127.0.0.1", port)
      servers << server
    rescue => e
      # The port can already be taken
    end
  end

  servers
end

def free_ports(servers)
  servers.each do |t|
    t.close rescue nil # the threads are blocked just kill
  end
end

describe LogStash::WebServer do
  before :all do
    @abort = Thread.abort_on_exception
    Thread.abort_on_exception = true
    WebMock.allow_net_connect!
  end

  after :all do
    Thread.abort_on_exception = @abort
  end

  let(:logger) { LogStash::Logging::Logger.new("testing") }
  let(:agent) { OpenStruct.new({
                                 webserver:       webserver_block,
                                 http_address:    "127.0.0.1",
                                 id:              "myid",
                                 name:            "myname",
                                 health_observer: org.logstash.health.HealthObserver.new,
                               }) }
  let(:webserver_block) { OpenStruct.new({}) }

  subject(:webserver) { LogStash::WebServer.new(logger, agent, webserver_options) }

  let(:webserver_options) do
    {
      :http_host => api_host,
      :http_ports => port_range,
    }
  end

  let(:port_range) { 10000..10010 }
  let(:api_host) { "127.0.0.1" }

  context "when an exception occur in the server thread" do
    let(:spy_output) { spy("stderr").as_null_object }

    it "should not log to STDERR" do
      skip("This test fails randomly, tracked in https://github.com/elastic/logstash/issues/9361.")
      backup_stderr = STDERR
      backup_stdout = STDOUT

      # We are redefining constants, so lets silence the warning
      silence_warnings do
        STDOUT = STDERR = spy_output
      end

      expect(spy_output).not_to receive(:puts).with(any_args)
      expect(spy_output).not_to receive(:write).with(any_args)

      # This trigger an infinite loop in the reactor
      expect(IO).to receive(:select).and_raise(IOError).at_least(:once)

      t = Thread.new do
        subject.run
      end

      sleep(1)

      # We cannot use stop here, since the code is stuck in an infinite loop
      t.kill
      t.join

      silence_warnings do
        STDERR = backup_stderr
        STDOUT = backup_stdout
      end
    end
  end

  context "when the port is already in use and a range is provided" do
    after(:each) { free_ports(@servers) }

    context "when we have available ports" do
      let(:blocked_range) { 10000..10005 }
      before(:each) do
        @servers = block_ports(blocked_range)
      end

      it "successfully find an available port" do
        t = Thread.new do
          subject.run
        end

        sleep(1)
        address = subject.address
        port = address.split(":").last.to_i
        expect(port_range).to cover(port)
        expect(blocked_range).to_not cover(port)

        response = ::URI.open("http://#{address}").read
        expect { LogStash::Json.load(response) }.not_to raise_error

        subject.stop
        t.join
      end
    end

    context "when all the ports are taken" do
      before(:each) do
        @servers = block_ports(port_range)
      end

      it "raise an exception" do
        expect { subject.run }.to raise_error(Errno::EADDRINUSE, /Logstash tried to bind to port range/)
      end
    end
  end

  describe "#validate_keystore_access!" do
    let(:keystore_password) { double("password", value: "changeit") }
    let(:mock_input_stream) { double("FileInputStream") }
    let(:ssl_params) { { keystore_path: "/path/to/keystore", keystore_password: keystore_password } }

    def stub_keystore_load(type)
      keystore = double("keystore")
      allow(java.security.KeyStore).to receive(:getInstance).with(type).and_return(keystore)
      allow(java.io.FileInputStream).to receive(:new).with("/path/to/keystore").and_return(mock_input_stream)
      allow(keystore).to receive(:load)
    end

    context "in non-FIPS mode" do
      before do
        allow(java.security.Security).to receive(:getProvider).with("BCFIPS").and_return(nil)
        allow(java.security.Security).to receive(:getProviders).and_return([])
        stub_keystore_load("JKS")
      end

      it "uses JKS by default" do
        ws = LogStash::WebServer.new(logger, agent, webserver_options.merge(:ssl_params => ssl_params))
        expect(java.security.KeyStore).to have_received(:getInstance).with("JKS")
      end
    end

    context "in FIPS mode" do
      let(:mock_bcfips) { double("BCFIPSProvider", getName: "BCFIPS") }

      before do
        allow(java.security.Security).to receive(:getProvider).with("BCFIPS").and_return(mock_bcfips)
        allow(java.security.Security).to receive(:getProviders).and_return([mock_bcfips])
      end

      it "uses BCFKS by default" do
        stub_keystore_load("BCFKS")
        ws = LogStash::WebServer.new(logger, agent, webserver_options.merge(:ssl_params => ssl_params))
        expect(java.security.KeyStore).to have_received(:getInstance).with("BCFKS")
      end

      it "uses the explicitly configured keystore type when provided" do
        stub_keystore_load("PKCS12")
        opts = webserver_options.merge(:ssl_params => ssl_params.merge(keystore_type: "PKCS12"))
        ws = LogStash::WebServer.new(logger, agent, opts)
        expect(java.security.KeyStore).to have_received(:getInstance).with("PKCS12")
      end
    end
  end

  context "when configured with http basic auth" do
    around(:each) do |example|
      begin
        thread = Thread.new(webserver, &:run)

        Stud.try(10.times) { fail('webserver not running') unless webserver.port }

        example.call
      ensure
        webserver.stop
        thread.join
      end
    end

    let(:password_policies) { {
      "mode": "ERROR",
      "length": { "minimum": "8"},
      "include": { "upper": "REQUIRED", "lower": "REQUIRED", "digit": "REQUIRED", "symbol": "REQUIRED" }
    } }
    let(:webserver_options) {
      super().merge(:auth_basic => {
         :username => "a-user",
         :password => LogStash::Util::Password.new("s3cur3dPas!"),
         :password_policies => password_policies
      }) }

    context "and no auth is provided" do
      it 'emits an HTTP 401 with WWW-Authenticate header' do
        response = Faraday.new("http://#{api_host}:#{webserver.port}").get('/')
        aggregate_failures do
          expect(response.status).to eq(401)
          expect(response.headers.to_hash).to include('www-authenticate' => 'Basic realm="logstash-api"')
        end
      end
    end
    context "and invalid basic auth is provided" do
      it 'emits an HTTP 401 with WWW-Authenticate header' do
        response = Faraday.new("http://#{api_host}:#{webserver.port}") do |conn|
          conn.request :authorization, :basic, 'john-doe', 'open-sesame'
        end.get('/')
        aggregate_failures do
          expect(response.status).to eq(401)
          expect(response.headers.to_hash).to include('www-authenticate' => 'Basic realm="logstash-api"')
        end
      end
    end
    context "and valid auth is provided" do
      it "returns a relevant response" do
        response = Faraday.new("http://#{api_host}:#{webserver.port}") do |conn|
          conn.request :authorization, :basic, 'a-user', 's3cur3dPas!'
        end.get('/')
        aggregate_failures do
          expect(response.status).to eq(200)
          expect(response.headers).to_not include('www-authenticate')
        end
        expect(response.body).to match(/\A{.*}\z/)
        decoded_response = LogStash::Json.load(response.body)
        expect(decoded_response).to include("id" => "myid")
      end
    end
  end
end

describe LogStash::IOWrappedLogger do
  let(:logger)  { spy("logger") }
  let(:message) { "foobar" }

  subject { described_class.new(logger) }

  it "responds to puts" do
    subject.puts(message)
    expect(logger).to have_received(:debug).with(message)
  end

  it "responds to write" do
    subject.write(message)
    expect(logger).to have_received(:debug).with(message)
  end

  it "responds to <<" do
    subject << message
    expect(logger).to have_received(:debug).with(message)
  end

  it "responds to sync=(v)" do
    expect { subject.sync = true }.not_to raise_error
  end

  it "responds to sync" do
    expect { subject.sync }.not_to raise_error
  end

  it "responds to flush" do
    expect { subject.flush }.not_to raise_error
  end
end
