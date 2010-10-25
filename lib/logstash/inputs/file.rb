require "logstash/namespace"
require "logstash/event"
require "eventmachine-tail"
require "uri"
require "socket" # for Socket.gethostname

class LogStash::Inputs::File
  def initialize(url, config={}, &block)
    @url = url
    @url = URI.parse(url) if url.is_a? String

    # Hack the hostname into the url.
    # This works since file:// urls don't generally have a host in it.
    @url.host = Socket.gethostname

    @config = config
    @callback = block
    @tags = []
  end

  public
  def register
    EventMachine::FileGlobWatchTail.new(@url.path, Reader, interval=60,
                                        exclude=[], receiver=self)
  end

  # TODO(sissel): Refactor this into a general 'input' class
  # tag this input
  public
  def tag(newtag)
    @tags << newtag
  end

  public
  def receive(event)
    event = LogStash::Event.new({
      "source" => @url.to_s,
      "message" => event,
      "tags" => @tags,
    })
    @callback.call(event)
  end # def event

  private
  class Reader < EventMachine::FileTail
    def initialize(path, receiver)
      super(path)
      @receiver = receiver
      @buffer = BufferedTokenizer.new  # From eventmachine
    end

    def receive_data(data)
      # TODO(sissel): Support multiline log data
      @buffer.extract(data).each do |line|
        @receiver.receive(line)
      end
    end # def receive_data
  end # class Reader
end # class LogStash::Inputs::File
