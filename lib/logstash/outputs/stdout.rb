# encoding: utf-8
require "logstash/outputs/base"
require "logstash/namespace"

# A simple output which prints to the STDOUT of the shell running
# Logstash. This output can be quite convenient when debugging
# plugin configurations, by allowing instant access to the event
# data after it has passed through the inputs and filters.
#
# For example, the following output configuration, in conjunction with the
# Logstash `-e` command-line flag, will allow you to see the results
# of your event pipeline for quick iteration. 
# 
#     output {
#       stdout {}
#     }
# 
# Useful codecs include:
#
# `rubydebug`: outputs event data using the ruby "awesome_print"
# library[http://rubygems.org/gems/awesome_print]
#
#     output {
#       stdout { codec => rubydebug }
#     }
#
# `json`: outputs event data in structured JSON format
#
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
  config :debug_format, :default => "ruby", :validate => ["ruby", "dots", "json"], :deprecated => true

  # The message to emit to stdout.
  config :message, :validate => :string, :deprecated => "You can use the 'line' codec instead. For example: output { stdout { codec => line { format => \"%{somefield} your message\" } } }"

  public
  def register
    if @debug
      require "logstash/codecs/rubydebug"
      require "logstash/codecs/dots"
      require "logstash/codecs/json"
      case @debug_format
        when "ruby"; @codec = LogStash::Codecs::RubyDebug.new
        when "json"; @codec = LogStash::Codecs::JSON.new
        when "dots"; @codec = LogStash::Codecs::Dots.new
      end
    elsif @message
      @codec = LogStash::Codecs::Line.new("format" => @message)
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
