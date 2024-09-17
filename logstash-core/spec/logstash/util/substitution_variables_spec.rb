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

require "spec_helper"
require "logstash/util/substitution_variables"

describe LogStash::Util::SubstitutionVariables do

  subject { Class.new { extend LogStash::Util::SubstitutionVariables } }

  context "ENV or Keystore ${VAR} with single/double quotes" do
    # single or double quotes come from ENV/Keystore ${VAR} value
    let(:xpack_monitoring_host) { '"http://node1:9200"' }
    let(:xpack_monitoring_hosts) { "'[\"http://node3:9200\", \"http://node4:9200\"]'" }
    let(:xpack_management_pipeline_id) { '"*"' }
    let(:config_string) {
      "'input {
        stdin { }
        beats { port => 5040 }
      }
      output {
        elasticsearch {
          hosts => [\"https://es:9200\"]
          user => \"elastic\"
          password => 'changeme'
        }
      }'"
    }

    # this happens mostly when running LS with docker
    it "stripes out quotes" do
      expect(subject.send(:strip_enclosing_char, xpack_monitoring_host, '"')).to eql('http://node1:9200')
      expect(subject.send(:strip_enclosing_char, xpack_monitoring_hosts, "'")).to eql('["http://node3:9200", "http://node4:9200"]')
      expect(subject.send(:strip_enclosing_char, xpack_management_pipeline_id, '"')).to eql('*')
      # make sure we keep the hosts, user and password param enclosed quotes
      expect(subject.send(:strip_enclosing_char, config_string, "'")).to eql('input {
        stdin { }
        beats { port => 5040 }
      }
      output {
        elasticsearch {
          hosts => ["https://es:9200"]
          user => "elastic"
          password => \'changeme\'
        }
      }')
    end
  end
end