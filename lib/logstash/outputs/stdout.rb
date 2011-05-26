require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base
  begin
     require "ap"
  rescue LoadError
  end

  config_name "stdout"

  # Enable debugging. Tries to pretty-print the entire event object.
  config :debug, :validate => :boolean

  # Debug output format: ruby (default), json
  config :debug_format, :default => ["ruby"], :validate => (lambda do |value|
    valid_formats = ["ruby", "json"]
    if value.length != 1
      false
    else
      valid_formats.member?(value.first)
    end
  end) # config :debug_format

  public
  def register
    @print_method = method(:ap) rescue method(:p)
  end

  public
  def receive(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end

    if @debug
      case @debug_format.first
        when "ruby"
          @print_method.call(event.to_hash)
        when "json"
          puts event.to_json
        else
          raise "unknown debug_format #{@debug_format}, this should never happen"
      end
    else
      puts event.to_s
    end
  end # def event
end # class LogStash::Outputs::Stdout
