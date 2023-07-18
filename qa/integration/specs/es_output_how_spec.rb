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
require_relative '../services/logstash_service'
require_relative 'spec_helper.rb'

describe "Test Elasticsearch output" do
  before(:all) {
    @fixture = Fixture.new(__FILE__)
    es_allow_wildcard_deletes(@fixture.get_service("elasticsearch").get_client)
  }

  after(:all) {
    clean_es(@fixture.get_service("elasticsearch").get_client)
    @fixture.teardown
  }

  it "can ingest 37K log lines of sample apache logs with default settings" do
    logstash_service = @fixture.get_service("logstash")
    es_service = @fixture.get_service("elasticsearch")
    logstash_service.start_with_input(@fixture.config("default"), @fixture.input)
    es_client = es_service.get_client
    # now we test if all data was indexed by ES, but first refresh manually
    es_client.indices.refresh
    result = es_client.search(index: '.ds-logs-*', size: 0, q: '*')
    expect(result).to have_hits(37)

    # randomly checked for results and structured fields
    result = es_client.search(index: '.ds-logs-*', size: 1, q: 'dynamic')
    expect(result).to have_hits(1)
    s = result["hits"]["hits"][0]["_source"]
    expect(s["bytes"]).to eq(18848)
    expect(s["response"]).to eq(200)
    expect(s["clientip"]).to eq("213.113.233.227")
  end

  it "can ingest 37K log lines of sample apache logs with ecs and data streams off" do
    logstash_service = @fixture.get_service("logstash")
    es_service = @fixture.get_service("elasticsearch")
    logstash_service.start_with_input(@fixture.config("ds_ecs_off"), @fixture.input)
    es_client = es_service.get_client
    # now we test if all data was indexed by ES, but first refresh manually
    es_client.indices.refresh
    result = es_client.search(index: 'logstash-*', size: 0, q: '*')
    expect(result).to have_hits(37)

    # randomly checked for results and structured fields
    result = es_client.search(index: 'logstash-*', size: 1, q: 'dynamic')
    expect(result).to have_hits(1)
    s = result["hits"]["hits"][0]["_source"]
    expect(s["bytes"]).to eq(18848)
    expect(s["response"]).to eq(200)
    expect(s["clientip"]).to eq("213.113.233.227")
    # Use a range instead of a fixed number
    # update on the geoip data can change the values
    expect(s["geoip"]["longitude"]).to be_between(-180, 180)
    expect(s["geoip"]["latitude"]).to be_between(-90, 90)
    expect(s["verb"]).to eq("GET")
    expect(s["useragent"]["os"]).to match(/Windows/)
  end
end
