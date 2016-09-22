require_relative '../framework/fixture'
require_relative '../framework/settings'
require_relative '../services/logstash_service'

describe "a config which indexes data into Elasticsearch" do

  before(:all) {
    @fixture = Fixture.new(__FILE__)
  }

  after(:all) {
    es_client = @fixture.get_service("elasticsearch").get_client
    es_client.indices.delete(index: 'logstash-*')
    @fixture.teardown
  }

  it "can ingest 300K log lines" do
    logstash_service = @fixture.get_service("logstash")
    es_service = @fixture.get_service("elasticsearch")
    puts "Ingesting 37 apache log lines to ES."
    logstash_service.start_with_input(@fixture.config, @fixture.input)
    es_client = es_service.get_client
    # now we test if all data was indexed by ES, but first refresh manually
    es_client.indices.refresh
    result = es_client.search(index: 'logstash-*', size: 0, q: '*')
    expect(result["hits"]["total"]).to eq(37)
  end

end
