require_relative "service_container"
require 'elasticsearch'
require 'docker'

class ElasticsearchService < ServiceContainer
  def initialize(settings)
    super("elasticsearch", settings)

    # Binding container to host ports.
    @container_create_opts[:HostConfig] = {
                                            :PortBindings => {
                                              '9200/tcp' => [{ :HostPort => '9200' }],
                                              '9300/tcp' => [{ :HostPort => '9300' }]
                                          }}
  end

  def get_client
    Elasticsearch::Client.new(:hosts => "localhost:9200")
  end

end
