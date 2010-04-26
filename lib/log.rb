require 'date'
require 'json'
#require 'ferret'

module LogStash
  class LogException < StandardError
  end

  class LogNotImplementedException < StandardError
  end

  class Log
    REQUIRED_KEYS = [:type, :encoding]
    OPTIONAL_KEYS = [:attrs, :date_key, :date_format, :logstash_dir,
                     :pattern_dir, :elasticsearch_host]
    attr_accessor :attrs

    LogParseError = Class.new(StandardError)

    def initialize(config)
      check_hash_keys(config, REQUIRED_KEYS, OPTIONAL_KEYS)

      @home = config[:logstash_dir] || "/opt/logstash"
      @pattern_dir = config[:pattern_dir] || @home
      @attrs = {"log:type" => config[:type],
                "log:encoding" => config[:encoding]}
      if config[:attrs]
        if not config[:attrs].is_a?(Hash)
          throw LogException.new(":attrs must be a hash")
        end

        config[:attrs].keys.each do |key|
          next unless key.to_s[0..3] == "log:"
          throw LogException.new("extra attrs must not begin with" +
                                  " log: (#{key})")
        end

        @attrs.merge!(config[:attrs])
      end

      @config = config
    end

    # passed a string that represents an "entry" in :import_type
    def import_entry(entry)
      throw LogNotImplementedException.new
    end

    def index_dir
      return "#{@home}/var/indexes/#{@attrs["log:type"]}"
    end

    def create_index
      return if File.exists?(index_dir)

      field_infos = Ferret::Index::FieldInfos.new(:store => :no,
                                                 :term_vector => :no)
      field_infos.add_field(:@LINE,
                            :store => :compressed,
                            :index => :no)
      [:@DATE, :@LOG_TYPE, :@SOURCE_HOST].each do |special|
        field_infos.add_field(special,
                              :store => :compressed,
                              :index => :untokenized)
      end
      field_infos.create_index(index_dir)
    rescue
      $logger.fatal "error creating index for #{@config[:type]}: #{$!}"
      exit(4)
    end

    def get_index
      #create_index unless File.exists?(index_dir)
      #return Ferret::Index::Index.new(:path => index_dir)
      #http = EventMachine::HttpRequest.new("http://localhost:9200/logstash/#{@config[:type]}")
      #req = http.post :body => entry.to_json
    end

    def index(entry)
      #$logger.debug("Logging #{entry}")
      http = EventMachine::HttpRequest.new("http://#{@config[:elasticsearch_host]}/logstash/#{@config[:type]}")
      req = http.post :body => entry.to_json
    end

    def fix_date(res)
      time = nil
      if @config[:date_key] and @config[:date_format] and \
         res[@config[:date_key]]
        raw_date = res[@config[:date_key]]
        time = nil
        begin
          time = DateTime.strptime(raw_date, @config[:date_format])
        rescue ArgumentError
          # time didn't parse
          time = DateTime.now
        end
      end
      time ||= DateTime.now
      res["@DATE"] = time.strftime("%s").to_i

      return res
    end

    private
    def check_hash_keys(hash, required_keys, optional_keys)
      required_keys.each do |key|
        next if hash.keys.member?(key)
        raise LogException.new("missing required key #{key}")
      end

      hash.keys.each do |key|
        next if required_keys.member?(key)
        next if optional_keys.member?(key)
        raise LogException.new("unknown key #{key}")
      end
    end
  end # class Log
end # module LogStash
