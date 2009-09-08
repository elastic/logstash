  #!/usr/bin/env ruby

require 'rubygems'
require 'lib/net/client'
require 'lib/net/messages/indexevent'
require 'lib/file/tail/since'
require 'stomp'
require 'socket'


class Agent < LogStash::Net::MessageClient
  def initialize(host, port)
    super(username="", password="", host=host, port=port)
    @hostname = Socket.gethostname
    @msgs = []
  end # def initialize

  def start_log_watcher
    @t1 = Thread.new do
      File::Tail::Since.new("/b/logs/auth.log.scorn").tail do |line|
        line.chomp!
        index("linux-syslog", line)
      end
    end

    #@t2 = Thread.new do
      #File::Tail::Since.new("/b/access.10k").tail do |line|
        #count = 0
        #line.chomp!
        #count += 1
        ##if count % 1000 == 0
          ##sleep 1
          #puts count
        #end
        #index("httpd-access", line)
        ##break if count >= 1
      #end
    #end
  end # def start_log_watcher

  def index(type, string)
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = type
    ier.log_data = string
    ier.metadata["source_host"] = @hostname

    #puts "Sending: #{ier}"
    sendmsg("/queue/logstash", ier)
  end # def index

  def IndexEventResponseHandler(msg)
    return if msg.code == 0
    puts msg.inspect
  end # def IndexEventResponseHandler

  def run
    start_log_watcher
    super
  end
end


if $0 == __FILE__
  if ARGV.length == 0
    puts "Usage: #{$0} host:port"
    exit 1
  end
  Thread::abort_on_exception = true
  host, port = ARGV[0].split(":")
  agent = Agent.new(host, port)
  agent.run
end
