require "logstash/inputs/threadable"
require "logstash/namespace"

class LogStash::Inputs::SQS < LogStash::Inputs::Threadable
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
    @messages_processed = 0
  end

  public
  def register
    @logger.info("Registering SQS input for queue '#{@queue}'")
    require "aws-sdk"
    @sqs = AWS::SQS.new(
      :access_key_id => @access_key,
      :secret_access_key => @secret_key
    )
    begin
      @logger.debug("Connecting to AWS SQS queue '#{@queue}'...")
      @sqs_queue = @sqs.queues.named(@queue)
      @logger.info("Connected to AWS SQS queue '#{@queue}' successfully.")
    rescue Exception => e
      @logger.error("Unable to access SQS queue '#{@queue}': #{e.to_s}")
      throw e
    end
  end

  public
  def run(output_queue)
    begin
      @logger.debug("Polling SQS queue '#{@queue}'...")
      poll_settings = {
        :initial_timeout => false, 
        :idle_timeout => 10, 
        :batch_size => 10, 
        :visibility_timeout => 10
      }
      @sqs_queue.poll() do |message|
        if message
          e = to_event(message.body, @sqs_queue)
          if e
            @logger.debug("Processed SQS message #{message.id} [#{message.md5}] from queue '#{@queue}'")
            puts "Processed SQS message #{message.id} [#{message.md5}] from queue '#{@queue}' (#{@messages_processed}) (#{e.source_host})"
            output_queue << e
            message.delete
            @messages_processed += 1
          end
        end
      end
    rescue Exception => e
      @logger.error("Erroring processing messages from AWS SQS queue '#{queue}': #{e.to_s}")
    end
  end

  def teardown
    @sqs_queue = nil
    finished
  end
end