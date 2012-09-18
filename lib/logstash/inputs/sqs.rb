require "logstash/inputs/base"
require "logstash/namespace"

class Logstash::Inputs::SQS < LogStash::Inputs::Base
  config_name "sqs"
  plugin_status "experimental"

  # SQS Queue name
  config :queue, :validate => :string, :required => true

  # IAM key/secret
  config :access_key, :validate => :string, :required => true
  config :secret_key, :validate => :string, :required => true

  def initialize(*args)
    super(*args)
  end

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
  def run(output_queue)
    @sqs_queue.poll(:initial_timeout => false, :idle_timeout => 10) do |message|
      output_queue << message if message
    end
  end
end