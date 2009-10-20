require "lib/config/base"

module LogStash; module Config
  class AgentConfig < BaseConfig
    attr_reader :sources
    attr_reader :logstash_dir

    def initialize(file)
      super(file)
      obj = YAML::load(File.open(file).read())

      @sources = obj["sources"]
    end # def initialize
  end # class AgentConfig
end; end # module LogStash::Config
