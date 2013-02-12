require "logstash/outputs/rabbitmq"

class LogStash::Outputs::AMQP < LogStash::Outputs::RabbitMQ
  def register
    @logger.warn("The 'amqp' output plugin has been renamed to 'rabbitmq'. " \
                 "Please update your configuration appropriately.")
    super
  end # def register
end # class LogStash::Outputs::AMQP
