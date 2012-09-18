require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::SQS < LogStash::Outputs::Base
  config_name "sqs"
  plugin_status "experimental"

  # SQS Queue name
  config :queue, :validate => :string, :required => true

  # IAM key/secret
  config :access_key, :validate => :string, :required => true
  config :secret_key, :validate => :string, :required => true

  public 
  def register
    require "aws-sdk"
    @sqs = AWS::SQS.new(
      :access_key_id => @access_key,
      :secret_access_key => @secret_key
    )
    @sqs_queue = @sqs.named(@queue)
    @logger.info("Connected to AWS SQS queue #{@queue}")
  end

  public
  def receive(event)
    @sqs_queue.send_message(event.to_hash)
  end
end