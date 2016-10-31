require "logstash/filters/base"
require "logstash/namespace"

# Show a string composed from event
# It's for debugging purpose, do not use it in production !
class LogStash::Filters::Show < LogStash::Filters::Base
  config_name "show"
  milestone 1

  # Specify text to show
  config :text, :validate => :string, :default => "%{host} %{message}"

  # Output to put the string: "logger", "stderr", "stdout", "filename"
  config :output, :validate => :string, :default => "logger"

  # if output if logger, set the loglevel [ "debug", "info", "warn", "error", "fatal" ]
  config :loglevel, :validate => :string, :default => "warn"

  public
  def register
    # Nothing
  end # def register

  public
  def filter(event)
    return unless filter?(event)
    finaltext = event.sprintf(@text)
    if @output == "logger"
        #don't know if is needed
        @logger.send(@loglevel, finaltext)
    elsif @output == "stderr"
        $stderr.puts finaltext
    elsif @output == "stdout"
        $stdout.puts finaltext
    else 
        File.open(@output, 'a') { |file| file.write("#{finaltext}\n") }
    end
    filter_matched(event)
  end # def filter
end # class LogStash::Filters::Environment
