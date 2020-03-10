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

require "logstash/elasticsearch_client"

describe LogStash::ElasticsearchClient do
  describe LogStash::ElasticsearchClient::RubyClient do
    let(:settings) { {} }
    let(:logger) { nil }

    describe "ssl option handling" do
      context "when using a string for ssl.enabled" do
        let(:settings) do
          { "var.elasticsearch.ssl.enabled" => "true" }
        end

        it "should set the ssl options" do
          expect(Elasticsearch::Client).to receive(:new) do |args|
            expect(args[:ssl]).to_not be_empty
          end
          described_class.new(settings, logger)
        end
      end

      context "when using a boolean for ssl.enabled" do
        let(:settings) do
          { "var.elasticsearch.ssl.enabled" => true }
        end

        it "should set the ssl options" do
          expect(Elasticsearch::Client).to receive(:new) do |args|
            expect(args[:ssl]).to_not be_empty
          end
          described_class.new(settings, logger)
        end
      end
    end
  end
end
