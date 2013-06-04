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
  config :debug, :validate => :boolean

  # Debug output format: ruby (default), json
  config :debug_format, :default => "ruby", :validate => ["ruby", "json", "dots"]

  # The message to emit to stdout.
  config :message, :validate => :string, :default => "%{+yyyy-MM-dd'T'HH:mm:ss.SSSZ} %{host}: %{message}"

  public
  def register
    @print_method = method(:ap) rescue method(:p)
    if @debug
      case @debug_format
        when "ruby"
          define_singleton_method(:receive) do |event|
            return unless output?(event)
            if event == LogStash::SHUTDOWN
              finished
              return
            end
            @print_method.call(event.to_hash)
          end
        when "json"
          define_singleton_method(:receive) do |event|
            return unless output?(event)
            if event == LogStash::SHUTDOWN
              finished
              return
            end
            puts event.to_json
          end
        when "dots"
          define_singleton_method(:receive) do |event|
            return unless output?(event)
            if event == LogStash::SHUTDOWN
              finished
              return
            end
            $stdout.write(".")
          end
        else
          raise "unknown debug_format #{@debug_format}, this should never happen"
      end
    else
      define_singleton_method(:receive) do |event|
        return unless output?(event)
        if event == LogStash::SHUTDOWN
          finished
          return
        end
        puts event.sprintf(@message)
      end
    end
  end

end # class LogStash::Outputs::Stdout
