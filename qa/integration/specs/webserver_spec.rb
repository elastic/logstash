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
require 'manticore'
require 'stud/try'

require 'logstash/util'
require 'logstash/webserver'

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
      Thread.abort_on_exception = true
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

  let(:certs_path) { File.expand_path("../../fixtures/webserver_certs/generated", __FILE__) }
  let(:ca_file) { File.join(certs_path, "root.crt") }
  let(:keystore_password) { "12345678" }

  %w(
      server_from_root.p12
      server_from_intermediate.p12
      server_from_root.jks
      server_from_intermediate.jks
    ).each do |keystore_name|
    context "when configured with keystore #{keystore_name}" do

      let(:keystore_path) { File.join(certs_path, "#{keystore_name}") }

      let(:ssl_params) { {:keystore_path => keystore_path, :keystore_password => LogStash::Util::Password.new(keystore_password)} }
      let(:webserver_options) { super().merge(:ssl_params => ssl_params) }

      context 'and invalid credentials' do
        let(:keystore_password) { "wrong" }
        it 'raises a helpful error' do
          expect { webserver }.to raise_error(ArgumentError, /keystore password was incorrect|or password was incorrect/) # .p12 vs .jks error message
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
              client = Manticore::Client.new(automatic_retries: 0, ssl: { })
              expect do
                client.get("https://127.0.0.1:#{webserver.port}").code
              end.to raise_error(Manticore::ClientProtocolException, a_string_including("unable to find valid certification path to requested target"))
            end
          end
        end

        context 'an HTTP request' do
          it 'fails' do
            client = Manticore::Client.new(automatic_retries: 1)
            expect do
              client.get("http://127.0.0.1:#{webserver.port}").code
            end.to raise_error(Manticore::ClientProtocolException, a_string_including("failed to respond"))
          end
        end
      end
    end

    context "when using truststore" do
      let(:keystore_path) { File.join(certs_path, 'server_from_root.p12') }
      let(:truststore_path) { File.join(certs_path, 'client_root.jks') }
      let(:ca_file) { File.join(certs_path, "root.crt") }

      let(:ssl_params) do
        {
          :keystore_path => keystore_path,
          :keystore_password => LogStash::Util::Password.new(keystore_password),
          :truststore_path => truststore_path
        }
      end
      let(:webserver_options) { super().merge(:ssl_params => ssl_params) }

      context "when started" do
        include_context 'running webserver'

        context 'an HTTPS request' do
          it 'succeeds' do
            client = Manticore::Client.new(automatic_retries: 0, ssl: { ca_file: ca_file })
            response = client.get("https://127.0.0.1:#{webserver.port}")
            expect(response.code).to eq(200)
          end

          # this is mostly a sanity check for our testing methodology
          # If this fails, we cannot trust success from the other specs
          context 'without providing CA' do
            it 'fails' do
              client = Manticore::Client.new(automatic_retries: 1, ssl: { })
              expect do
                client.get("https://127.0.0.1:#{webserver.port}").code
              end.to raise_error(Manticore::ClientProtocolException, a_string_including("unable to find valid certification path to requested target"))
            end
          end
        end

        context 'full verification' do

          let(:ssl_params) { super().merge :verification_mode => 'full' }
          let(:client_cert) { File.join(certs_path, "client_from_root.crt") }
          let(:client_key) { File.join(certs_path, "client_from_root.key") }

          let(:curl_base_opts) { "--tlsv1.2 --tls-max 1.3" }

          it 'works with client certificate' do
            expect(logger).to_not receive(:info)

            # NOTE: not using Manticore as I failed to get it to properly sent client certificate during TLS.
            # client = Manticore::Client.new(automatic_retries: 0,
            #                                ssl: { ca_file: ca_file,
            #                                       client_cert: OpenSSL::X509::Certificate.new(File.read(client_cert)),
            #                                       client_key: OpenSSL::PKey.read(client_key),
            #                                       verify: :strict })

            curl_opts = curl_base_opts + " --cacert #{ca_file}" + " --cert #{client_cert}" + " --key #{client_key}"
            res = do_curl("https://127.0.0.1:#{webserver.port}", curl_opts)
          end

          it 'fails' do
            expect(logger).to receive(:info).with('SSL error', hash_including(error: kind_of(Puma::MiniSSL::SSLError)))

            curl_opts = curl_base_opts + " --cacert #{ca_file}"
            expect do
              do_curl("https://127.0.0.1:#{webserver.port}", curl_opts)
            end.to raise_error(RuntimeError, /Empty reply from server/)
          end
        end
      end
    end

  end

  def do_curl(url, opts); require 'open3'
    cmd = "curl -s -v --show-error #{opts} -X GET -k #{url}"
    begin
      out, err, status = Open3.capture3(cmd)
    rescue Errno::ENOENT
      fail "curl not available, make sure curl binary is installed and available on $PATH"
    end

    if status.success?
      http_status = err.match(/< HTTP\/1.1 (\d+)/)[1] || '0' # < HTTP/1.1 200 OK\r\n

      if http_status.strip[0].to_i > 2
        warn out
        fail "#{cmd.inspect} unexpected response: #{http_status}\n\n#{err}"
      end
      return http_status
    else
      warn out
      fail "#{cmd.inspect} process failed: #{status}\n\n#{err}"
    end
  end

end