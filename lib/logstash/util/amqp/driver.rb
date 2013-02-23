require 'logstash/namespace'

module LogStash::Rabbitmq
  def self.driver_class
    if RUBY_ENGINE == "jruby"
      require "logstash/util/amqp/java_driver"
      LogStash::Rabbitmq::JavaDriver
    else
      require "logstash/util/amqp/mri_driver"
      LogStash::Rabbitmq::MRIDriver
    end

  end

  class Driver
    attr_reader :connection
    def initialize(opts)
    end

    def setup_input(scope)

    end

    def setup_output(scope)

    end

    def subscribe(&block)

    end

    def publish(event, opts = {})

    end
  end
end