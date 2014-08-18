# encoding: utf-8
require "logstash/inputs/threadable"
require "logstash/namespace"
require "logstash/timestamp"
require "logstash/plugin_mixins/aws_config"
require "digest/sha2"

# Pull events from an Amazon Web Services Simple Queue Service (SQS) queue.
#
# SQS is a simple, scalable queue system that is part of the
# Amazon Web Services suite of tools.
#
# Although SQS is similar to other queuing systems like AMQP, it
# uses a custom API and requires that you have an AWS account.
# See http://aws.amazon.com/sqs/ for more details on how SQS works,
# what the pricing schedule looks like and how to setup a queue.
#
# To use this plugin, you *must*:
#
#  * Have an AWS account
#  * Setup an SQS queue
#  * Create an identify that has access to consume messages from the queue.
#
# The "consumer" identity must have the following permissions on the queue:
#
#  * sqs:ChangeMessageVisibility
#  * sqs:ChangeMessageVisibilityBatch
#  * sqs:DeleteMessage
#  * sqs:DeleteMessageBatch
#  * sqs:GetQueueAttributes
#  * sqs:GetQueueUrl
#  * sqs:ListQueues
#  * sqs:ReceiveMessage
#
# Typically, you should setup an IAM policy, create a user and apply the IAM policy to the user.
# A sample policy is as follows:
#
#     {
#       "Statement": [
#         {
#           "Action": [
#             "sqs:ChangeMessageVisibility",
#             "sqs:ChangeMessageVisibilityBatch",
#             "sqs:GetQueueAttributes",
#             "sqs:GetQueueUrl",
#             "sqs:ListQueues",
#             "sqs:SendMessage",
#             "sqs:SendMessageBatch"
#           ],
#           "Effect": "Allow",
#           "Resource": [
#             "arn:aws:sqs:us-east-1:123456789012:Logstash"
#           ]
#         }
#       ]
#     }
#
# See http://aws.amazon.com/iam/ for more details on setting up AWS identities.
#
class LogStash::Inputs::SQS < LogStash::Inputs::Threadable
  include LogStash::PluginMixins::AwsConfig

  config_name "sqs"
  milestone 1

  default :codec, "json"

  # Name of the SQS Queue name to pull messages from. Note that this is just the name of the queue, not the URL or ARN.
  config :queue, :validate => :string, :required => true

  # Name of the event field in which to store the SQS message ID
  config :id_field, :validate => :string

  # Name of the event field in which to store the SQS message MD5 checksum
  config :md5_field, :validate => :string

  # Name of the event field in which to store the  SQS message Sent Timestamp
  config :sent_timestamp_field, :validate => :string

  public
  def aws_service_endpoint(region)
    return {
        :sqs_endpoint => "sqs.#{region}.amazonaws.com"
    }
  end

  public
  def register
    @logger.info("Registering SQS input", :queue => @queue)
    require "aws-sdk"

    @sqs = AWS::SQS.new(aws_options_hash)

    begin
      @logger.debug("Connecting to AWS SQS queue", :queue => @queue)
      @sqs_queue = @sqs.queues.named(@queue)
      @logger.info("Connected to AWS SQS queue successfully.", :queue => @queue)
    rescue Exception => e
      @logger.error("Unable to access SQS queue.", :error => e.to_s, :queue => @queue)
      throw e
    end # begin/rescue
  end # def register

  public
  def run(output_queue)
    @logger.debug("Polling SQS queue", :queue => @queue)

    receive_opts = {
        :limit => 10,
        :visibility_timeout => 30,
        :attributes => [:sent_at]
    }

    continue_polling = true
    while running? && continue_polling
      continue_polling = run_with_backoff(60, 1) do
        @sqs_queue.receive_message(receive_opts) do |message|
          if message
            @codec.decode(message.body) do |event|
              decorate(event)
              if @id_field
                event[@id_field] = message.id
              end
              if @md5_field
                event[@md5_field] = message.md5
              end
              if @sent_timestamp_field
                event[@sent_timestamp_field] = LogStash::Timestamp.new(message.sent_timestamp).utc
              end
              @logger.debug? && @logger.debug("Processed SQS message", :message_id => message.id, :message_md5 => message.md5, :sent_timestamp => message.sent_timestamp, :queue => @queue)
              output_queue << event
              message.delete
            end # codec.decode
          end # valid SQS message
        end # receive_message
      end # run_with_backoff
    end # polling loop
  end # def run

  def teardown
    @sqs_queue = nil
    finished
  end # def teardown

  private
  # Runs an AWS request inside a Ruby block with an exponential backoff in case
  # we exceed the allowed AWS RequestLimit.
  #
  # @param [Integer] max_time maximum amount of time to sleep before giving up.
  # @param [Integer] sleep_time the initial amount of time to sleep before retrying.
  # @param [Block] block Ruby code block to execute.
  def run_with_backoff(max_time, sleep_time, &block)
    if sleep_time > max_time
      @logger.error("AWS::EC2::Errors::RequestLimitExceeded ... failed.", :queue => @queue)
      return false
    end # retry limit exceeded

    begin
      block.call
    rescue AWS::EC2::Errors::RequestLimitExceeded
      @logger.info("AWS::EC2::Errors::RequestLimitExceeded ... retrying SQS request", :queue => @queue, :sleep_time => sleep_time)
      sleep sleep_time
      run_with_backoff(max_time, sleep_time * 2, &block)
    rescue AWS::EC2::Errors::InstanceLimitExceeded
      @logger.warn("AWS::EC2::Errors::InstanceLimitExceeded ... aborting SQS message retreival.")
      return false
    rescue Exception => bang
      @logger.error("Error reading SQS queue.", :error => bang, :queue => @queue)
      return false
    end # begin/rescue
    return true
  end # def run_with_backoff
end # class LogStash::Inputs::SQS
