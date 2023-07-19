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

# Ruby doesn't have common class for boolean,
# And to simplify the ResourceDSLMethods check it make sense to have it.
module Boolean; end

class TrueClass
  include Boolean
end

class FalseClass
  include Boolean
end

module ResourceDSLMethods
  # Convert a nested hash to a mapping of key paths to expected classes
  def hash_to_mapping(h, path = [], mapping = {})
    h.each do |k, v|
      if v.is_a?(Hash)
        hash_to_mapping(v, path + [k], mapping)
      else
        full_path = path + [k]
        mapping[full_path] = v
      end
    end
    mapping
  end

  def test_api(expected, path)
    context "GET #{path}" do
      let(:payload) { LogStash::Json.load(last_response.body) }

      before(:all) do
        get path
      end

      it "should respond OK" do
        expect(last_response).to be_ok
      end

      describe "the default metadata" do
        it "should include the host" do
          expect(payload["host"]).to eql(Socket.gethostname)
        end

        it "should include the version" do
          expect(payload["version"]).to eql(LOGSTASH_CORE_VERSION)
        end

        it "should include the http address" do
          skip("flaky test tracked in https://github.com/elastic/logstash/issues/11385")
          expect(payload["http_address"]).to eql("127.0.0.1:#{::LogStash::WebServer::DEFAULT_PORTS.first}")
        end

        it "should include the node name" do
          expect(payload["name"]).to eql(@agent.name)
        end

        it "should include the node id" do
          expect(payload["id"]).to eql(@agent.id)
        end
      end

      hash_to_mapping(expected).each do |resource_path, klass|
        dotted = resource_path.join(".")

        it "should set '#{dotted}' at '#{path}' to be a '#{klass}'" do
          expect(last_response).to be_ok # fail early if need be
          resource_path_value = resource_path.reduce(payload) do |acc, v|
            expect(acc).to be_a(Hash), "Got a nil looking for #{resource_path} in #{payload}"
            expect(acc.has_key?(v)).to eql(true), "Expected to find value '#{v}' in structure '#{acc}', but could not. Payload was '#{payload}'"
            acc[v]
          end
          expect(resource_path_value).to be_a(klass), "could not find '#{dotted}' in #{payload}"
        end
      end
    end

    yield if block_given? # Add custom expectations
  end

  def test_api_and_resources(expected, xopts = {})
    xopts[:exclude_from_root] ||= []
    root_expectation = expected.clone
    xopts[:exclude_from_root].each {|k| root_expectation.delete(k)}
    test_api(root_expectation, "/")

    expected.keys.each do |key|
      test_api({key => expected[key]}, "/#{key}")
    end
  end
end
