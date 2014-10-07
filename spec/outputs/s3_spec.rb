require "spec_helper"
require "logstash/outputs/s3"

describe LogStash::Outputs::S3 do
  before do
    AWS.stub!
  end

  describe 'should allow to use the IAM roles without specifying the credentials' do
    config <<-CONFIG
      input {
        generator {
          message => "valid"
          count => 1
        }
      }

      output {
        s3 {
          host => "localhost"
          sender => "spec"
          count => [ "test.valid", "0.1" ]
        }
      }
    CONFIG

    agent do

    end
  end
end
