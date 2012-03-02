require "test_helper"
require "logstash/outputs/sns"
require "aws-sdk"

describe LogStash::Outputs::Sns do
  before do
    # Fake SNS object
    @topic = stub()
    @topic_collection = stub(:[] => @topic)
    @sns = stub(:topics => @topic_collection)

    # Some default values for an event
    @event = LogStash::Event.new
    @event.timestamp = '2012-02-01T20:37:28.394000Z'
    @event.source = "file://ip-10-40-211-234/var/log/messages"
    @event.message = "Feb  1 15:37:27 localhost systemd-logind[384]: New session 265 of user ec2-user."

    # Sample AWS credentials
    @aws_creds = { :secret_access_key => '54321z', :access_key_id => '12345a' }
  end

  describe '.register' do
    before do
      YAML.stubs(:load_file => @aws_creds)
      AWS::SNS.stubs(:new => @sns)
    end

    test 'registers an SNS proxy without publishing a boot message' do
      sns_output = LogStash::Outputs::Sns.new(
        'credentials' => ['/fake/file.yml']
      )
      @topic_collection.expects(:[]).never

      sns_output.register
    end

    test 'publishes a boot message when able to create a SNS proxy' do
      sns_output = LogStash::Outputs::Sns.new(
        'credentials' => ['/fake/file.yml'],
        'publish_boot_message_arn' => ['fake_boot_arn']
      )

      @topic_collection.expects(:[]).with('fake_boot_arn').returns(@topic)
      @topic.expects(:publish).with(instance_of(String), has_entries(:subject => instance_of(String)))

      sns_output.register
    end
  end

  describe '.receive' do
    before do
      # Need to have a registered SNS proxy
      YAML.stubs(:load_file => @aws_creds)
      AWS::SNS.stubs(:new => @sns)

      @subject = LogStash::Outputs::Sns.new(
          'credentials' => ['/fake/file.yml']
        )
      @subject.register

      @arn = 'fake:arn'
      @event.fields['sns'] = @arn
    end

    test 'does not send a message to SNS when an event should not be output' do
      @subject.stubs(:output? => false)
      @topic.expects(:publish).never

      @subject.receive(@event)
    end

    test 'raises an exception when an event with no sns field is received' do
      @event.fields.delete('sns')
      @topic.expects(:publish).never

      assert_raises(RuntimeError) { @subject.receive(@event) }
    end

    test 'uses the sns_subject when one is provided' do
      @event.fields['sns_subject'] = 'Test subject'
      @topic.expects(:publish).with(instance_of(String), :subject => 'Test subject')

      @subject.receive(@event)
    end

    test 'uses the sns_message when one is provided' do
      @event.fields['sns_message'] = 'Test message'
      @topic.expects(:publish).with('Test message', has_entries(:subject => instance_of(String)))

      @subject.receive(@event)
    end

    test 'uses a default message and subject when no sns_message or sns_subject are provided' do
      @topic.expects(:publish).with(instance_of(String), has_entries(:subject => instance_of(String)))

      @subject.receive(@event)
    end
  end

  describe '#format_message' do
    test 'formats messages with tags and fields correctly' do
      @event.fields['field1'] = 'val1'
      @event.fields['field2'] = 'val2'
      @event.tags << 'tag1' << 'tag2'

      msg = LogStash::Outputs::Sns.format_message(@event)
      assert msg =~ /field1/
      assert msg =~ /tag2/
    end

    test 'truncates messages that are too long' do
      @event.message = 'hi'*LogStash::Outputs::Sns::MAX_MESSAGE_SIZE
      msg = LogStash::Outputs::Sns.format_message(@event)

      assert_equal 2 * LogStash::Outputs::Sns::MAX_MESSAGE_SIZE, @event.message.length
      assert_equal LogStash::Outputs::Sns::MAX_MESSAGE_SIZE, msg.length
    end
  end
end
