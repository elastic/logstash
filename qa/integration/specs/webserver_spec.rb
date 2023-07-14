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

require 'openssl'

require 'logstash/util'
require 'logstash/webserver'
require "stud/try"
require "manticore"

describe 'api webserver' do
  let!(:logger) { double("Logger").as_null_object }
  let!(:agent) { double("Agent").as_null_object }
  subject(:webserver) { LogStash::WebServer.new(logger, agent, webserver_options) }

  let(:webserver_options) { Hash.new }

  # provide a shared context to take care of ensuring that the webserver
  # is running during the spec runs of examples in the including context
  shared_context 'running webserver' do
    let(:webserver) { defined?(super()) ? super() : fail("included context requires `webserver` to be present") }

    # since we are running the webserver on another
    # thread, ensure that a crash doesn't go unnoticed.
    around(:each) do |example|
      abort = Thread.abort_on_exception
      example.call
      Thread.abort_on_exception = abort
    end

    # If webmock is active, allow real network connections
    before(:each) { WebMock.allow_net_connect! if defined?(WebMock) }

    # ensure our API webserver is running with the provided config
    # before running our specs that validate responses
    let!(:webserver_thread) { Thread.new(webserver, &:run) }
    before(:each) do
      Stud.try(10.times) { fail('API WebServer not running yet...') unless webserver.port }
    end
    after(:each) do
      webserver.stop
      webserver_thread.join
    end
  end

  context "when configured with api.ssl.supported_protocols" do
    let(:ca_file) { File.join(certs_path, "root.crt") }
    let(:certs_path) { File.expand_path("../../fixtures/webserver_certs/generated", __FILE__) }
    let(:keystore_path) { File.join(certs_path,  "server_from_root.p12") }
    let(:keystore_password) { "12345678" }
    let(:supported_protocols) { %w[TLSv1.3] }
    let(:ssl_params) { {:supported_protocols => supported_protocols, :keystore_path => keystore_path, :keystore_password => LogStash::Util::Password.new(keystore_password)} }
    let(:webserver_options) { super().merge(:ssl_params => ssl_params) }
    let(:client_protocols) { nil }
    let(:client) { Manticore::Client.new(ssl: { ca_file: ca_file, protocols: client_protocols }) }
    let(:response) { client.get("https://127.0.0.1:#{webserver.port}") }

    include_context 'running webserver'

    context 'an HTTPS request using TLSv1.3' do
      let(:client_protocols) { %w[TLSv1.3] }
      it 'succeeds' do
        expect(response.code).to eq(200)
      end
    end

    context 'an HTTPS request using TLSv1.2' do
      let(:client_protocols) { %w[TLSv1.2] }
      it 'fails' do
        expect { response.code }.to raise_error(Manticore::ClientProtocolException, a_string_including("handshake"))
      end
    end
  end

  %w(
      server_from_root.p12
      server_from_intermediate.p12
      server_from_root.jks
      server_from_intermediate.jks
    ).each do |keystore_name|
    context "when configured with keystore #{keystore_name}" do
      let(:ca_file) { File.join(certs_path, "root.crt") }
      let(:certs_path) { File.expand_path("../../fixtures/webserver_certs/generated", __FILE__) }
      let(:keystore_path) { File.join(certs_path, "#{keystore_name}") }
      let(:keystore_password) { "12345678" }

      let(:ssl_params) { {:keystore_path => keystore_path, :keystore_password => LogStash::Util::Password.new(keystore_password)} }
      let(:webserver_options) { super().merge(:ssl_params => ssl_params) }

      context 'and invalid credentials' do
        let(:keystore_password) { "wrong" }
        it 'raises a helpful error' do
          expect { webserver }.to raise_error(ArgumentError, a_string_including("keystore password was incorrect"))
        end
      end

      context "when started" do
        include_context 'running webserver'

        context 'an HTTPS request' do
          it 'succeeds' do
            client = Manticore::Client.new(ssl: { ca_file: ca_file })
            response = client.get("https://127.0.0.1:#{webserver.port}")
            expect(response.code).to eq(200)
          end

          # this is mostly a sanity check for our testing methodology
          # If this fails, we cannot trust success from the other specs
          context 'without providing CA' do
            it 'fails' do
              client = Manticore::Client.new(ssl: { })
              expect do
                client.get("https://127.0.0.1:#{webserver.port}").code
              end.to raise_error(Manticore::ClientProtocolException, a_string_including("unable to find valid certification path to requested target"))
            end
          end
        end

        context 'an HTTP request' do
          it 'fails' do
            client = Manticore::Client.new
            expect do
              client.get("http://127.0.0.1:#{webserver.port}").code
            end.to raise_error(Manticore::ClientProtocolException, a_string_including("failed to respond"))
          end
        end
      end
    end
  end
end
