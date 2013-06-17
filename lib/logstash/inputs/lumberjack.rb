require "logstash/inputs/base"
require "logstash/namespace"

# Receive events using the lumberjack protocol.
#
# This is mainly to receive events shipped  with lumberjack,
# <http://github.com/jordansissel/lumberjack>
class LogStash::Inputs::Lumberjack < LogStash::Inputs::Base

  config_name "lumberjack"
  milestone 1

  # the address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # the port to listen on.
  config :port, :validate => :number, :required => true

  # ssl certificate to use
  config :ssl_certificate, :validate => :path, :required => true

  # ssl key to use
  config :ssl_key, :validate => :path, :required => true

  # ssl key passphrase to use
  config :ssl_key_passphrase, :validate => :password

  # TODO(sissel): Add CA to authenticate clients with.

  public
  def register
    require "lumberjack/server"

    @logger.info("Starting lumberjack input listener", :address => "#{@host}:#{@port}")
    @lumberjack = Lumberjack::Server.new(:address => @host, :port => @port,
      :ssl_certificate => @ssl_certificate, :ssl_key => @ssl_key,
      :ssl_key_passphrase => @ssl_key_passphrase)
  end # def register

  public
  def run(output_queue)
    @lumberjack.run do |l|
      file = l.delete("file")
      if file[0,1] == "/"
        source = "lumberjack://#{l.delete("host")}#{file}"
      else
        source = "lumberjack://#{l.delete("host")}/#{file}"
      end
      event = to_event(l.delete("line"), source)

      # TODO(sissel): We shoudln't use 'fields' here explicitly, but the new
      # 'event[key]' code seems... slow, so work around it for now.
      # TODO(sissel): Once Event_v1 is live, we can just merge 'l' directly into it.
      #l.each do |key, value|
        #event[key] = value
      #end
      event.fields.merge!(l)

      output_queue << event
    end
  end # def run
end # class LogStash::Inputs::Lumberjack
