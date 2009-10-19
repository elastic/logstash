require 'yaml'
require 'lib/logs'
require 'lib/log/json'
require 'lib/log/text'

module LogStash::Config
  class IndexerConfig
    attr_reader :logs
    attr_reader :logstash_dir
    attr_reader :mqhost
    attr_reader :mqport
    attr_reader :mquser
    attr_reader :mqpass
    attr_reader :mqvhost

    def initialize(file)
      obj = YAML::load(File.open(file).read())

      @mqhost = obj["mqhost"] || "localhost"
      @mqport = obj["mqport"] || 5672
      @mquser = obj["mquser"] || "guest"
      @mqpass = obj["mqpass"] || "guest"
      @mqvhost = obj["mqvhost"] || "/"
      @logstash_dir = obj["logstash_dir"]
      @logs = LogStash::Logs.new

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
  end # class IndexerConfig
end # module LogStash::Config
