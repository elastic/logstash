require "logstash/outputs/rabbitmq"

# This plugin has been renamed to 'rabbitmq'. Please use that one instead.
class LogStash::Outputs::AMQP < LogStash::Outputs::RabbitMQ
  config_name "amqp"
  milestone 2
  def register
    @logger.warn("The 'amqp' output plugin has been renamed to 'rabbitmq'. " \
                 "Please update your configuration appropriately.")
    super
  end # def register
end # class LogStash::Outputs::AMQP
