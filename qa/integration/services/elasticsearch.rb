require 'elasticsearch'

class ElasticsearchService < Service
  def initialize(settings)
    super("elasticsearch", settings)
  end

  def get_client
    Elasticsearch::Client.new(:hosts => "localhost:9200")
  end

end