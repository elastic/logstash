require "test_utils"
require "logstash/filters/csv"


describe LogStash::Filters::Csv do
  extend LogStash::RSpec

  describe "warn user of missing configuration" do
    it "should log a warning message when no source => dest in config" do
      # Mock a loggerIO
      logger = double("logger")
      logger.should_receive(:is_a?).any_number_of_times do |arg|
        arg == :IO
      end
      #Expect warning
      logger.should_receive(:<<).with({:message=> LogStash::Filters::Csv::WARNING_MSG_EMPTY_CONFIG, :level=>:warn})
      #Run agent (as in test_utils) but injecting our mock logger in the plugin
      #(would have loved to use Cabin::Channel.get somehow)
      require "logstash/config/file"
      configString = <<-CONFIG
      filter {
        csv {
          fields => ["custom1", "custom2", "custom3"]
        }
      }
      CONFIG
      config = LogStash::Config::File.new(nil, configString)
      agent = LogStash::Agent.new
      @inputs, @filters, @outputs = agent.instance_eval { parse_config(config) }
      [@inputs, @filters, @outputs].flatten.each do |plugin|
        #Inject logger in filter 
        plugin.logger.subscribe(logger)
        plugin.register
      end
    end
  end

  describe "parse csv with field names" do
    config <<-CONFIG
    filter {
      csv {
        raw => "data"
        fields => ["custom1", "custom2", "custom3"]
      }
    }
    CONFIG

    sample({"@fields" => {"raw" => "val1,val2,val3"}}) do
      insist { subject["data"] } == {"custom1" => "val1", "custom2" => "val2",  "custom3" => "val3"}
    end
  end

  describe "parse csv without field names" do
    config <<-CONFIG
    filter {
      csv {
        raw => "data"
      }
    }
    CONFIG

    sample({"@fields" => {"raw" => "val1,val2,val3"}}) do
      insist { subject["data"] } == {"field1" => "val1", "field2" => "val2",  "field3" => "val3"}
    end
  end

  describe "parse csv with more data than defined field names" do
    config <<-CONFIG
    filter {
      csv {
        raw => "data"
        fields => ["custom1", "custom2"]
      }
    }
    CONFIG

    sample({"@fields" => {"raw" => "val1,val2,val3"}}) do
      insist { subject["data"] } == {"custom1" => "val1", "custom2" => "val2",  "field3" => "val3"}
    end
  end
  describe "fail to parse any data in a multi-value field" do
    config <<-CONFIG
    filter {
      csv {
        raw => "data"
        fields => ["custom1", "custom2"]
      }
    }
    CONFIG

    sample({"@fields" => {"raw" => ["val1,val2,val3", "val1,val2,val3"]}}) do
      insist { subject["data"] } == nil
    end
  end
end
