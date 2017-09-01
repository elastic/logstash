require_relative "service"

class KafkaService < Service
  def initialize(settings)
    super("kafka", settings)
  end
end
