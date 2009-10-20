require 'lib/config/base'
require 'lib/logs'
require 'lib/log/json'
require 'lib/log/text'

module LogStash; module Config
  class IndexerConfig < BaseConfig
    attr_reader :logs
    attr_reader :logstash_dir
    attr_reader :pattern_dir

    def initialize(file)
      super(file)
      obj = YAML::load(File.open(file).read())

      @logstash_dir = obj["logstash_dir"]
      @pattern_dir = obj["pattern_dir"]
      @logs = LogStash::Logs.new

      obj["log-types"].each do |log_type, data|
        log = nil
        log_config = {:type => log_type,
                      :date_key => data["date"]["key"],
                      :date_format => data["date"]["format"],
                      :logstash_dir => @logstash_dir,
                      :pattern_dir => @pattern_dir,
                     }

        case data["type"]
        when "text"
          log_config[:grok_patterns] = data["patterns"]
          log = LogStash::Log::TextLog.new(log_config)
        when "json"
          log_config[:line_format] = data["display_format"]
          log = LogStash::Log::JsonLog.new(log_config)
        end

        @logs.register(log)
      end
    end # def initialize
  end # class IndexerConfig
end; end # module LogStash::Config
