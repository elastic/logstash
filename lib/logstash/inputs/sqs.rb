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
      puts "Connecting to AWS SQS queue '#{@queue}'..."
      @logger.debug("Connecting to AWS SQS queue '#{@queue}'...")
      @sqs_queue = @sqs.queues.named(@queue)
      puts "Connected to AWS SQS queue '#{@queue}' successfully."
      @logger.info("Connected to AWS SQS queue '#{@queue}' successfully.")
    rescue Exception => e
      puts "Unable to access SQS queue '#{@queue}': #{e.to_s}"
      @logger.error("Unable to access SQS queue '#{@queue}': #{e.to_s}")
      throw e
    end
  end

  public
  def run(output_queue)
    begin
      puts "Polling SQS queue '#{@queue}'..."
      @sqs_queue.poll(:initial_timeout => false, :idle_timeout => 10) do |message|
        puts "Message: #{message.to_s}"
        if message
          e = to_event(message.body, @sqs_queue)
          if e
            output_queue << e
          end
        end
      end
    rescue Exception => e
      puts "Erroring processing messages from AWS SQS queue '#{queue}': #{e.to_s}"
      @logger.error("Erroring processing messages from AWS SQS queue '#{queue}': #{e.to_s}")
    end
  end

  def teardown
    puts "Starting teardown"
    finished
    puts "teardown complete"
  end
end