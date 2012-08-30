require "insist"

module LogStash
  module RSpec
    def config(configstr)
      require "logstash/config/file"
      @config = LogStash::Config::File.new(nil, configstr)
    end # def config

    def sample(event, &block)
      subject do
        { 
          "foo" => "bar",
          "@tags" => [ "foo" ]
        }
      end
      context("when processing #{event.inspect}", &block)
    end # def sample
  end # module RSpec
end # module LogStash

