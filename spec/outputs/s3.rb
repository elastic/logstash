require "test_utils"

require "logstash/outputs/s3"
require "rspec/mocks"

describe LogStash::Outputs::S3 do
  extend LogStash::RSpec

  describe "format the message" do

    it 'should not blow up if there are no tags' do
      event = { "[@timestamp]" => "such timestamp",
                "source" => "source wow",
                "tags" => nil }
      #event = double('event')
      #event.should_receive(:[]).with('@timestamp')
      #event.should_receive(:[]).with('source')
      #event.should_receive(:[]).with('tags')
      lambda {
        LogStash::Outputs::S3.format_message(event)
      }.should_not raise_error 
    end

    it 'should not blow up if there are tags' do
      event = { "[@timestamp]" => "such timestamp",
                "source" => "source wow",
                "tags" => ['foo','bar'] }
      lambda {
        LogStash::Outputs::S3.format_message(event)
    }.should_not raise_error 
    end
  end
end
