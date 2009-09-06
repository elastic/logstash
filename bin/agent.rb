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
    #@t1 = Thread.new do
      #File::Tail::Since.new("/var/log/messages").tail do |line|
        #line.chomp!
        #index("linux-syslog", line)
      #end
    ##end

    @t2 = Thread.new do
      #File::Tail::Since.new("/b/access.10").tail do |line|
      begin
        count = 0
        File.open("/b/access.1k").readlines.each do |line|
          line.chomp!
          index("httpd-access", line)
          count += 1
          #break if count >= 3
        end
      rescue => e
        $stderr.puts e.inspect
        $stderr.puts caller.join("\n")
        raise e
      end
      #close
    end
    @t2.join
  end # def start_log_watcher

  def index(type, string)
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = type
    ier.log_data = string
    ier.metadata["source_host"] = @hostname

    puts "Sending: #{ier}"
    sendmsg("/queue/logstash", ier)
  end # def index

  def IndexEventResponseHandler(msg)
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
  host, port = ARGV[0].split(":")
  agent = Agent.new(host, port)
  agent.run
end
