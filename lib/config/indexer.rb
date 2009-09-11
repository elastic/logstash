require 'yaml'
require 'lib/logs'
require 'lib/log/json'
require 'lib/log/text'



module LogStash::Config
  class IndexerConfig
    attr_reader :logs
    attr_reader :logstash_dir

    def initialize(file)
      obj = YAML::load(File.open(file).read())

      @stompserver = obj["stompserver"]
      @logstash_dir = obj["logstash_dir"]
      @logs = LogStash::Logs.new

      if @stompserver == nil
        raise ArgumentError.new("stompserver is nil (#{file})")
      end

      obj["log-types"].each do |log_type, data|
        log = nil
        #puts ":: #{log_type}"
        case data["type"]
        when "text"
          
          log = LogStash::Log::TextLog.new(:type => log_type,
                                           :grok_patterns => data["patterns"],
                                           :date_key => data["date"]["key"],
                                           :date_format => data["date"]["format"],
                                           :logstash_dir => @logstash_dir)
        when "json"
          log = LogStash::Log::JsonLog.new(:type => log_type,
                                           :line_format => data["display_format"],
                                           :date_key => data["date"]["key"],
                                           :date_format => data["date"]["format"],
                                           :logstash_dir => @logstash_dir)
        end

        @logs.register(log)
      end
    end

    def stomphost
      return @stompserver.split(":")[0]
    end

    def stompport
      port = @stompserver.split(":")[1].to_i  
      return (port == 0 ? 61613 : port)
    end
  end # class IndexerConfig
end # module LogStash::Config
