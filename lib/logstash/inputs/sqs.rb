require "logstash/inputs/base"
require "logstash/namespace"

class Logstash::Inputs::SQS < LogStash::Inputs::Threadable
  config_name "sqs"
  plugin_status "experimental"

  # SQS Queue name
  config :queue, :validate => :string, :required => true

  # IAM key/secret
  config :access_key, :validate => :string, :required => true
  config :secret_key, :validate => :string, :required => true

  def initialize(params)
    super
    @format ||= "json_event"
  end

  public
  def register
    require "aws-sdk"
    @sqs = AWS::SQS.new(
      :access_key_id => @access_key,
      :secret_access_key => @secret_key
    )
    @sqs_queue = @sqs.queues.named(@queue)
    @logger.info("Connected to AWS SQS queue #{@queue}")
  end

  public
  def run(output_queue)
    @sqs_queue.poll(:initial_timeout => false, :idle_timeout => 10) do |message|
      if message
        e = to_event(data.body, @sqs_queue)
        if e
          output_queue << e
        end
      end
    end
  end
end