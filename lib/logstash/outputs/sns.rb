# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"
require "logstash/plugin_mixins/aws_config"

# SNS output.
#
# Send events to Amazon's Simple Notification Service, a hosted pub/sub
# framework.  It supports subscribers of type email, HTTP/S, SMS, and SQS.
#
# For further documentation about the service see:
#
#   http://docs.amazonwebservices.com/sns/latest/api/
#
# This plugin looks for the following fields on events it receives:
#
#  * `sns` - If no ARN is found in the configuration file, this will be used as
#  the ARN to publish.
#  * `sns_subject` - The subject line that should be used.
#  Optional. The "%{host}" will be used if not present and truncated at
#  `MAX_SUBJECT_SIZE_IN_CHARACTERS`.
#  * `sns_message` - The message that should be
#  sent. Optional. The event serialzed as JSON will be used if not present and
#  with the @message truncated so that the length of the JSON fits in
#  `MAX_MESSAGE_SIZE_IN_BYTES`.
#
class LogStash::Outputs::Sns < LogStash::Outputs::Base
  include LogStash::PluginMixins::AwsConfig

  MAX_SUBJECT_SIZE_IN_CHARACTERS  = 100
  MAX_MESSAGE_SIZE_IN_BYTES       = 32768

  config_name "sns"
  milestone 1

  # Message format.  Defaults to plain text.
  config :format, :validate => [ "json", "plain" ], :default => "plain"

  # SNS topic ARN.
  config :arn, :validate => :string

  # When an ARN for an SNS topic is specified here, the message
  # "Logstash successfully booted" will be sent to it when this plugin
  # is registered.
  #
  # Example: arn:aws:sns:us-east-1:770975001275:logstash-testing
  #
  config :publish_boot_message_arn, :validate => :string

  public
  def aws_service_endpoint(region)
    return {
        :sns_endpoint => "sns.#{region}.amazonaws.com"
    }
  end

  public
  def register
    require "aws-sdk"

    @sns = AWS::SNS.new(aws_options_hash)

    # Try to publish a "Logstash booted" message to the ARN provided to
    # cause an error ASAP if the credentials are bad.
    if @publish_boot_message_arn
      @sns.topics[@publish_boot_message_arn].publish("Logstash successfully booted", :subject => "Logstash booted")
    end
  end

  public
  def receive(event)
    return unless output?(event)

    arn     = Array(event["sns"]).first || @arn

    raise "An SNS ARN required." unless arn

    message = Array(event["sns_message"]).first
    subject = Array(event["sns_subject"]).first || event.source

    # Ensure message doesn't exceed the maximum size.
    if message
      # TODO: Utilize `byteslice` in JRuby 1.7: http://jira.codehaus.org/browse/JRUBY-5547
      message = message.slice(0, MAX_MESSAGE_SIZE_IN_BYTES)
    else
      if @format == "plain"
        message = self.class.format_message(event)
      else
        message = self.class.json_message(event)
      end
    end

    # Log event.
    @logger.debug("Sending event to SNS topic [#{arn}] with subject [#{subject}] and message:")
    message.split("\n").each { |line| @logger.debug(line) }

    # Publish the message.
    @sns.topics[arn].publish(message, :subject => subject.slice(0, MAX_SUBJECT_SIZE_IN_CHARACTERS))
  end

  def self.json_message(event)
    json      = event.to_json
    json_size = json.bytesize

    # Truncate only the message if the JSON structure is too large.
    if json_size > MAX_MESSAGE_SIZE_IN_BYTES
      # TODO: Utilize `byteslice` in JRuby 1.7: http://jira.codehaus.org/browse/JRUBY-5547
      event["message"] = event["message"].slice(0, (event["message"].bytesize - (json_size - MAX_MESSAGE_SIZE_IN_BYTES)))
    end

    event.to_json
  end

  def self.format_message(event)
    message =  "Date: #{event.timestamp}\n"
    message << "Source: #{event["source"]}\n"
    message << "Tags: #{event["tags"].join(', ')}\n"
    message << "Fields: #{event.to_hash.inspect}\n"
    message << "Message: #{event["message"]}"

    # TODO: Utilize `byteslice` in JRuby 1.7: http://jira.codehaus.org/browse/JRUBY-5547
    message.slice(0, MAX_MESSAGE_SIZE_IN_BYTES)
  end
end
