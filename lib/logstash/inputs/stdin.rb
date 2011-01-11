require "eventmachine-tail"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket" # for Socket.gethostname

class LogStash::Inputs::Stdin < LogStash::Inputs::Base
  public
  def register
    EventMachine::attach($stdin, InputHandler, self)
    @url.host = Socket.gethostname
  end # def register

  public
  def receive(event)
    event = LogStash::Event.new({
      "@message" => event,
      "@type" => @type,
      "@tags" => @tags.clone,
    })
    event.source = @url
    @logger.debug(["Got event", event])
    @callback.call(event)
  end # def receive

  class InputHandler < EventMachine::Connection
    def initialize(obj)
      @receiver = obj
    end # def initialize

    def receive_data(data)
      @buffer ||= BufferedTokenizer.new
      @buffer.extract(data).each do |line|
        @receiver.receive(line)
      end
    end # def receive_data
  end # class InputHandler

end # class LogStash::Inputs::Stdin
