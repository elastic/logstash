require_relative "service"

class Kafka < Service
  def initialize(settings)
    super("kafka", settings)
  end
end  