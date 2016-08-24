require_relative "kafka"
require_relative "elasticsearch"

# This is a registry used in Fixtures so a test can get back any service class
# at runtime
# All new services should register here
class ServiceLocator

  def initialize(settings)
    @services = {}
    @services["logstash"] = Logstash.new(settings)
    @services["kafka"] = Kafka.new(settings)
    @services["elasticsearch"] = ElasticsearchService.new(settings)
  end

  def get_service(name)
    @services[name]
  end
end
