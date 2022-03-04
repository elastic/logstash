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

require "pluginmanager/utils/http_client"
require "net/http"
require "uri"

describe LogStash::PluginManager::Utils::HttpClient do
  subject  { described_class }

  describe ".start" do
    context "with ssl" do
      let(:uri) { URI.parse("https://localhost:8888") }

      it "requires ssl" do
        expect(Net::HTTP).to receive(:start).with(uri.host, uri.port, anything, anything, anything, anything, hash_including(:use_ssl => true))
        described_class.start(uri)
      end
    end

    context "without ssl" do
      let(:uri) { URI.parse("http://localhost:8888") }

      it "doesn't requires ssl" do
        expect(Net::HTTP).to receive(:start).with(uri.host, uri.port, anything, anything, anything, anything, hash_including(:use_ssl => false))
        described_class.start(uri)
      end
    end

    context "with a proxy" do
      let(:uri) { URI.parse("http://localhost:8888") }
      let(:proxy) { "http://user:pass@host.local:8080" }

      before(:each) do
        allow(ENV).to receive(:[]).with("https_proxy").and_return(proxy)
      end

      it "sets proxy arguments" do
        expect(Net::HTTP).to receive(:start).with(uri.host, uri.port, "host.local", 8080, "user", "pass", hash_including(:use_ssl => false))
        described_class.start(uri)
      end
    end

    context "without a proxy" do
      let(:uri) { URI.parse("http://localhost:8888") }

      before(:each) do
        allow(ENV).to receive(:[]).with("https_proxy").and_return(nil)
        allow(ENV).to receive(:[]).with("HTTPS_PROXY").and_return(nil)
      end

      it "doesn't set proxy arguments" do
        expect(Net::HTTP).to receive(:start).with(uri.host, uri.port, nil, nil, nil, nil, hash_including(:use_ssl => false))
        described_class.start(uri)
      end
    end
  end

  describe ".remove_file_exist?" do
    let(:mock_http) { double("Net::HTTP") }

    before do
      allow(subject).to receive(:start).with(anything).and_yield(mock_http).at_least(:once)
    end

    context "With URI with a path" do
      let(:uri) { URI.parse("https://localhost:8080/hola") }

      context "without redirect" do
        before do
          expect(mock_http).to receive(:request).with(kind_of(Net::HTTP::Head)).and_return(response)
        end

        context "file exist" do
          let(:response) { instance_double("Net::HTTP::Response", :code => "200") }

          it "returns true if the file exist" do
            expect(subject.remote_file_exist?(uri)).to be_truthy
          end
        end

        [404, 400, 401, 500].each do |code|
          context "when the server return a #{code}" do
            let(:response) { instance_double("Net::HTTP::Response", :code => code) }

            it "returns false" do
              expect(subject.remote_file_exist?(uri)).to be_falsey
            end
          end
        end
      end

      context "with redirects" do
        let(:location) { "https://localhost:8888/new_path" }
        let(:redirect_response) { instance_double("Net::HTTP::Response", :code => "302", :headers => { "location" => location }) }
        let(:response_ok) { instance_double("Net::HTTP::Response", :code => "200") }

        before(:each) do
          allow(redirect_response).to receive(:[]).with("location").and_return(location)
        end
        it "follow 1 level redirect" do
          expect(mock_http).to receive(:request).with(kind_of(Net::HTTP::Head)).and_return(redirect_response)
          expect(mock_http).to receive(:request).with(kind_of(Net::HTTP::Head)).and_return(response_ok)

          expect(subject.remote_file_exist?(uri)).to be_truthy
        end

        it "follow up to the limit of redirect: #{described_class::REDIRECTION_LIMIT - 1}" do
          (described_class::REDIRECTION_LIMIT - 1).times do
            expect(mock_http).to receive(:request).with(kind_of(Net::HTTP::Head)).and_return(redirect_response)
          end

          expect(mock_http).to receive(:request).with(kind_of(Net::HTTP::Head)).and_return(response_ok)

          expect(subject.remote_file_exist?(uri)).to be_truthy
        end

        it "raises a `RedirectionLimit` when too many redirection occur" do
          described_class::REDIRECTION_LIMIT.times do
            expect(mock_http).to receive(:request).with(kind_of(Net::HTTP::Head)).and_return(redirect_response)
          end

          expect { subject.remote_file_exist?(uri) }.to raise_error(LogStash::PluginManager::Utils::HttpClient::RedirectionLimit)
        end
      end

      context "With URI without a path" do
        let(:uri) { URI.parse("https://localhost:8080") }

        it "return false" do
          expect(subject.remote_file_exist?(uri)).to be_falsey
        end
      end
    end
  end
end
