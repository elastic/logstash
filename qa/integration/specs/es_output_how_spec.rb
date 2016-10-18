require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'

describe "Test Elasticsearch output" do

  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    es_client = @fixture.get_service("elasticsearch").get_client
    es_client.indices.delete(index: 'logstash-*')
    @fixture.teardown
  }

  it "can ingest 37K log lines of sample apache logs" do
    logstash_service = @fixture.get_service("logstash")
    es_service = @fixture.get_service("elasticsearch")
    logstash_service.start_with_input(@fixture.config, @fixture.input)
    es_client = es_service.get_client
    # now we test if all data was indexed by ES, but first refresh manually
    es_client.indices.refresh
    result = es_client.search(index: 'logstash-*', size: 0, q: '*')
    expect(result["hits"]["total"]).to eq(37)
    
    # randomly checked for results and structured fields
    result = es_client.search(index: 'logstash-*', size: 1, q: 'dynamic')
    expect(result["hits"]["total"]).to eq(1)
    s = result["hits"]["hits"][0]["_source"]
    expect(s["bytes"]).to eq(18848)
    expect(s["response"]).to eq(200)
    expect(s["clientip"]).to eq("213.113.233.227")
    expect(s["geoip"]["longitude"]).to eq(12.9443)
    expect(s["geoip"]["latitude"]).to eq(56.1357)
    expect(s["verb"]).to eq("GET")
    expect(s["useragent"]["os"]).to eq("Windows 7")
  end

end
