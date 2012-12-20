require "logstash/inputs/base"
require "logstash/namespace"

# Stream events from a heroku app's logs.
#
# This will read events in a manner similar to how the `heroku logs -t` command
# fetches logs.
#
# Recommended filters:
#
#     filter {
#       grok {
#         pattern => "^%{TIMESTAMP_ISO8601:timestamp} %{WORD:component}\[%{WORD:process}(?:\.%{INT:instance:int})?\]: %{DATA:message}$"
#       }
#       date { timestamp => ISO8601 }
#     }
class LogStash::Inputs::Heroku < LogStash::Inputs::Base
  config_name "heroku"
  plugin_status "experimental"

  # The name of your heroku application. This is usually the first part of the 
  # the domain name 'my-app-name.herokuapp.com'
  config :app, :validate => :string, :required => true

  public
  def register
    require "heroku"
    require "logstash/util/buftok"
  end # def register

  public
  def run(queue)
    client = Heroku::Client.new(Heroku::Auth.user, Heroku::Auth.password)
    source = "heroku://#{@app}"

    # The 'Herok::Client#read_logs' method emits chunks of text not bounded
    # by event barriers like newlines.
    buffer = FileWatch::BufferedTokenizer.new
    # tail=1 means to follow logs
    # I *think* setting num=1 means we only get 1 historical event. Setting
    # this to 0 makes it fetch *all* events, not what I want.
    client.read_logs(@app, ["tail=1", "num=1"]) do |chunk|
      buffer.extract(chunk).each do |line|
        # 'line' is plain text.
        @logger.debug("Received line", :app => @app, :line => line)
        e = to_event(line, source)
        queue << e if e
      end # buffer.extract
    end
  end # def run
end # class LogStash::Inputs::Heroku
