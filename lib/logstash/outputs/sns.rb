require "logstash/outputs/base"
require "logstash/namespace"

# SNS output.
#
# Send events to Amazon's Simple Notification Service, a hosted pub/sub
# framework.  It supports subscribers of type email, HTTP/S, SMS, and
# SQS.  See http://aws.amazon.com/sns/ and
# http://docs.amazonwebservices.com/sns/latest/api/API_Publish.html
#
# This plugin looks for the following fields on events it receives:
#  'sns' => The ARN of the topic this event should be sent to.  Required.
#  'sns_subject' => The subject line that should be used.  Optional.  "Notice from %{@source}" will be used if not present.
#  'sns_message' => The message that should be sent.  Optional.  The event's date, source, tags, fields, and message will be used if not present.
class LogStash::Outputs::Sns < LogStash::Outputs::Base
  MAX_SUBJECT_SIZE = 100
  MAX_MESSAGE_SIZE = 8192

  config_name "sns"
  plugin_status "experimental"

  # Path to YAML file containing a hash of AWS credentials.  Ex:
  # The path to YAML file containing a hash of the AWS credentials for your
  # account.  The contents of the file should look like this:
  # --- 
  # :aws_access_key_id: "12345"
  # :aws_secret_access_key: "54321"
  config :credentials, :validate => :string, :required => true

  # When an ARN for an SNS topic is specified here, the message "Logstash
  # successfully booted" will be sent to it when this plugin is registered.
  # Ex: "arn:aws:sns:us-east-1:770975001275:logstash-testing"
  config :publish_boot_message_arn, :validate => :string

  public
  def register
    require "fog"
    access_creds = YAML.load_file(@credentials)

    @sns = Fog::AWS::SNS.new(access_creds)

    # Try to get a list of the topics on this account to cause an error ASAP if the creds are bad
    if @publish_boot_message_arn
      @sns.publish(@publish_boot_message_arn, "Logstash successfully booted", 'Subject' => "Logstash booted")
    end
  end # def register

  public
  def receive(event)
    return unless output?(event)

    arn = Array(event.fields['sns']).first
    raise "Field 'sns' is required.  Event was #{event.type}, #{event.source}" unless arn

    message = Array(event.fields['sns_message']).first || self.class.format_message(event)
    subject = Array(event.fields['sns_subject']).first || "Notice from #{event.source}"

    @logger.debug("Sending event to SNS topic #{arn} with subject '#{subject}' and message:")
    message.split("\n").each { |line| @logger.debug(line) }

    @sns.publish(arn, message, 'Subject' => subject.slice(0, MAX_SUBJECT_SIZE))
  end # def receive

  public
  def self.format_message(event)
    message =  "Date: #{event.timestamp}\n"
    message << "Source: #{event.source}\n"
    message << "Tags: #{event.tags.join(', ')}\n"
    message << "Fields: #{event.fields.inspect}\n"
    message << "Message: #{event.message}"

    message.slice(0, MAX_MESSAGE_SIZE)
  end # def format_message
end # class LogStash::Outputs::Sns
