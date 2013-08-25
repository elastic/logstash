require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base
  begin
     require "ap"
  rescue LoadError
  end

  config_name "stdout"
  milestone 3
  
  default :codec, "line"

  # Enable debugging. Tries to pretty-print the entire event object.
  config :debug, :validate => :boolean, :default => false

  # Debug output format: ruby (default), json
  config :debug_format, :default => "ruby", :validate => ["ruby", "dots"], :deprecated => true

  # The message to emit to stdout.
  config :message, :validate => :string, :default => "%{+yyyy-MM-dd'T'HH:mm:ss.SSSZ} %{host}: %{message}"

  public
  def register
    @print_method = method(:ap) rescue method(:p)

    if @debug
      require "logstash/codecs/rubydebug"
      require "logstash/codecs/dots"
      case @debug_format
        when "ruby"; @codec = LogStash::Codecs::RubyDebug.new
        when "dots"; @codec = LogStash::Codecs::Dots.new
      end
    end
    @codec.on_event do |event|
      $stdout.write(event)
    end
  end

  def receive(event)
    return unless output?(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end
    @codec.encode(event)
  end

end # class LogStash::Outputs::Stdout
