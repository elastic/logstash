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
    @logger.debug("Polling SQS queue '#{@queue}'...")
    
    receive_opts = {
      :limit => 10,
      :visibility_timeout => 30
    }

    continue_polling = true
    while running? && continue_polling
      continue_polling = run_with_backoff(60, 1, "retrieving messages from SQS queue '#{@queue}'") do
        @sqs_queue.receive_message(receive_opts) do |message|
          if message
            e = to_event(message.body, @sqs_queue)
            if e
              @logger.debug("Processed SQS message #{message.id} [#{message.md5}] from queue '#{@queue}'")
              output_queue << e
              message.delete
            end
          end
        end
      end
    end
  end

  def teardown
    @sqs_queue = nil
    finished
  end

  private
  # Runs an AWS request inside a Ruby block with an exponential backoff in case
  # we exceed the allowed AWS RequestLimit.
  #
  # @param [Integer] max_time maximum amount of time to sleep before giving up.
  # @param [Integer] sleep_time the initial amount of time to sleep before retrying.
  # @param [message] message message to display if we get an exception.
  # @param [Block] block Ruby code block to execute.
  def run_with_backoff(max_time, sleep_time, message, &block)
    if sleep_time > max_time
      puts "AWS::EC2::Errors::RequestLimitExceeded ... failed #{message}"
      return false
    end
    
    begin
      yield
    rescue AWS::EC2::Errors::RequestLimitExceeded
      puts "AWS::EC2::Errors::RequestLimitExceeded ... retrying #{message} in #{sleep_time} seconds"
      sleep sleep_time
      run_with_backoff(max_time, sleep_time * 2, message, &block)
    rescue AWS::EC2::Errors::InstanceLimitExceeded
      puts "AWS::EC2::Errors::InstanceLimitExceeded ... aborting launch."
      return false
    rescue Error => bang
      print "Error for #{message}: #{bang}"
      return false
    end
    true
  end
end