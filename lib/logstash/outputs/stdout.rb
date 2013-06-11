require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Stdout < LogStash::Outputs::Base
  begin
     require "ap"
  rescue LoadError
  end

  config_name "stdout"
  plugin_status "stable"

  # Enable debugging. Tries to pretty-print the entire event object.
  config :debug, :validate => :boolean, :default => false

  # Debug output format: ruby (default), json
  config :debug_format, :default => "ruby", :validate => ["ruby", "dots"]

  # The message to emit to stdout.
  config :message, :validate => :string, :default => "%{+yyyy-MM-dd'T'HH:mm:ss.SSSZ} %{host}: %{message}"

  public
  def register
    @print_method = method(:ap) rescue method(:p)
    if @debug
      case @debug_format
        when "ruby"
          @codec.on_event do |event|
            @print_method.call(event)
          end
        when "dots"
          @codec.on_event do |event|
            $stdout.write(".")
          end
        else
          raise "unknown debug_format #{@debug_format}, this should never happen"
      end
    else
      @codec.on_event do |event|
        puts event
      end
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
