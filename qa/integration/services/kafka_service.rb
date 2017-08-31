require_relative "service"
require "logstash/devutils/rspec/logstash_helpers"

class KafkaService < Service
  include LogStashHelper

  def initialize(settings)
    super("kafka", settings)
  end
end
