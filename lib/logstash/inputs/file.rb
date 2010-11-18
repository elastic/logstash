require "logstash/inputs/base"
require "eventmachine-tail"
require "socket" # for Socket.gethostname

class LogStash::Inputs::File < LogStash::Inputs::Base
  def initialize(url, type, config={}, &block)
    super

    # Hack the hostname into the url.
    # This works since file:// urls don't generally have a host in it.
    @url.host = Socket.gethostname
  end

  def register
    EventMachine::FileGlobWatchTail.new(@url.path, Reader, interval=60,
                                        exclude=[], receiver=self)
  end # def register

  def receive(filetail, event)
    url = @url.clone
    url.path = filetail.path
    @logger.debug(["original url", { :originalurl => @url, :newurl => url }])
    event = LogStash::Event.new({
      "@message" => event,
      "@type" => @type,
      "@tags" => @tags.clone,
    })
    event.source = url
    @logger.debug(["Got event", event])
    @callback.call(event)
  end # def receive

  class Reader < EventMachine::FileTail
    def initialize(path, receiver)
      super(path)
      @receiver = receiver
      @buffer = BufferedTokenizer.new  # From eventmachine
    end

    def receive_data(data)
      # TODO(2.0): Support multiline log data
      @buffer.extract(data).each do |line|
        @receiver.receive(self, line)
      end
    end # def receive_data
  end # class Reader
end # class LogStash::Inputs::File
