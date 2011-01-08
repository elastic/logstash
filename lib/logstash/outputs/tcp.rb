require "logstash/outputs/base"
require "logstash/namespace"

class LogStash::Outputs::Tcp < LogStash::Outputs::Base
  public
  def register
    # TODO(sissel): Write generic validation methods
    if !@url.host or !@url.port
      @logger.fatal("No host or port given in #{self.class}: #{@url}")
      # TODO(sissel): Make this an actual exception class
      raise "configuration error"
    end

    @connection = EventMachine::connect(@url.host, @url.port)
  end # def register

  public
  def receive(event)
    @connection.send_data(event.to_hash.to_json)
    @connection.send_data("\n")
  end # def receive
end # class LogStash::Outputs::Tcp
