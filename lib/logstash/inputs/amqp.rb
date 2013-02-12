require "logstash/inputs/rabbitmq"

class LogStash::Inputs::AMQP < LogStash::Inputs::RabbitMQ
  def register
    @logger.warn("The 'amqp' input plugin has been renamed to 'rabbitmq'. " \
                 "Please update your configuration appropriately.")
    super
  end # def register
end # class LogStash::Inputs::AMQP
