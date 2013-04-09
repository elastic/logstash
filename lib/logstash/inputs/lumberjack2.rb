require "logstash/inputs/base"
require "logstash/namespace"

# Receive events using the lumberjack2 protocol.
#
# This is mainly to receive events shipped with lumberjack,
# <http://github.com/jordansissel/lumberjack>
class LogStash::Inputs::Lumberjack2 < LogStash::Inputs::Base

  config_name "lumberjack2"
  plugin_status "experimental"

  # The address to listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on.
  config :port, :validate => :number, :required => true

  # The path to your nacl private key. 
  # You can generate this with the lumberjack 'keygen' tool
  config :my_secret_key, :validate => :path, :required => true

  # The path to the client's nacl public key. 
  # You can generate this with the lumberjack 'keygen' tool
  config :their_public_key, :validate => :path, :required => true

  public
  def register
    require "lumberjack/server2"

    @logger.info("Starting lumberjack2 input listener", :address => "tcp://#{@host}:#{@port}")

    @lumberjack = Lumberjack::Server2.new(
      :endpoint => "tcp://#{@host}:#{@port}",
      :my_secret_key => File.read(@my_secret_key),
      :their_public_key => File.read(@their_public_key))
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
      event.fields.merge(l)

      output_queue << event
    end
  end # def run
end # class LogStash::Inputs::Lumberjack
