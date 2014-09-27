require "test_utils"
require "logstash/pipeline"
require "logstash/outputs/rabbitmq"

describe LogStash::Outputs::RabbitMQ do
  extend LogStash::RSpec

  describe "rabbitmq static key" do
    config <<-END
      input {
        generator {
          count => 1
        }
      }
      output {
        rabbitmq {
          host => "localhost"
          exchange_type => "topic"
          exchange => "foo"
          key => "bar"
        }
      }
    END

    it "should use defined key" do
      exchange = double("exchange")
      expect_any_instance_of(LogStash::Outputs::RabbitMQ).to receive(:connect).and_return(nil)
      expect_any_instance_of(LogStash::Outputs::RabbitMQ).to receive(:declare_exchange).and_return(exchange)

      expect(exchange).to receive(:publish).with(an_instance_of(String), {:routing_key => "bar", :properties => {:persistent => true}})

      # we need to set expectations before running the pipeline, this is why we cannot use the
      # "agent" spec construct here so we do it manually
      pipeline = LogStash::Pipeline.new(config)
      pipeline.run
    end

  end

  describe "rabbitmq key with dynamic field" do
    config <<-END
      input {
        generator {
          count => 1
          add_field => ["foo", "bar"]
        }
      }
      output {
        rabbitmq {
          host => "localhost"
          exchange_type => "topic"
          exchange => "foo"
          key => "%{foo}"
        }
      }
    END

    it "should populate the key with the content of the event foo field" do
      exchange = double("exchange")
      expect_any_instance_of(LogStash::Outputs::RabbitMQ).to receive(:connect).and_return(nil)
      expect_any_instance_of(LogStash::Outputs::RabbitMQ).to receive(:declare_exchange).and_return(exchange)

      expect(exchange).to receive(:publish).with(an_instance_of(String), {:routing_key => "bar", :properties => {:persistent => true}})

      # we need to set expectations before running the pipeline, this is why we cannot use the
      # "agent" spec construct here so we do it manually
      pipeline = LogStash::Pipeline.new(config)
      pipeline.run
    end

  end
end
