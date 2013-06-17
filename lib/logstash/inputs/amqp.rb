require "logstash/inputs/rabbitmq"

# This plugin has been renamed to 'rabbitmq'. Please use that one instead.
class LogStash::Inputs::AMQP < LogStash::Inputs::RabbitMQ
  config_name "amqp"
  milestone 2
  def register
    @logger.warn("The 'amqp' input plugin has been renamed to 'rabbitmq'. " \
                 "Please update your configuration appropriately.")
    super
  end # def register
end # class LogStash::Inputs::AMQP
