require 'lib/config/base'
require 'lib/logs'
require 'lib/log/json'
require 'lib/log/text'

module LogStash; module Config
  class AgentConfig < BaseConfig
    attr_reader :logs
    attr_reader :watched_paths
    attr_reader :logstash_dir
    attr_reader :pattern_dir

    def initialize(file)
      super(file)
      @logstash_dir = "/var/logstash"
      @pattern_dir = "/opt/logstash/patterns"
      @watched_paths = []
      @logs = LogStash::Logs.new

      data = YAML::load(::File.open(file).read())
      merge!(data)
    end

    def merge!(data)
      @pattern_dir = data["pattern_dir"] if data.has_key?("pattern_dir")
      @logstash_dir = data["logstash_dir"] if data.has_key?("logstash_dir")
      @watched_paths = data["watch"] if data.has_key?("watch")

      if data.has_key?("log-types")
        data["log-types"].each do |log_type, log_data|
          puts "Got log #{log_type}"
          log_config = {:type => log_type,
                        :date_key => log_data["date"]["key"],
                        :date_format => log_data["date"]["format"],
                        :logstash_dir => @logstash_dir,
                        :pattern_dir => @pattern_dir,
                       }

          log = nil
          case log_data["type"]
          when "text"
            log_config[:grok_patterns] = log_data["patterns"]
            log = LogStash::Log::TextLog.new(log_config)
          when "json"
            log_config[:line_format] = log_data["display_format"]
            log = LogStash::Log::JsonLog.new(log_config)
          end

          @logs.register(log)
        end
      end
    end # def merge!
  end # class AgentConfig
end; end # module LogStash::Config
