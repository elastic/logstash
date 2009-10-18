#!/usr/bin/env ruby

require 'rubygems'
require 'lib/net/client'
require 'lib/net/messages/indexevent'
require 'lib/net/messages/quit'
require 'lib/file/tail/since'
require 'stomp'
require 'socket'

class Agent < LogStash::Net::MessageClient
  def initialize(config)
    host, port = config["server"].split(":")
    host ||= "localhost"
    port ||= 61613
    super(username="", password="", host=host, port=port)
    @hostname = Socket.gethostname
    @config = config
    @msgs = []
  end # def initialize

  def start_log_watcher
    @config["sources"].each do |file, logtype|
      Thread.new do
        File::Tail::Since.new(file).tail do |line|
          index(logtype, line.chomp)
        end
      end
    end
  end # def start_log_watcher

  def index(type, string)
    ier = LogStash::Net::Messages::IndexEventRequest.new
    ier.log_type = type
    ier.log_data = string.strip_upper_ascii
    ier.metadata["source_host"] = @hostname

    puts "Indexing: #{string}"

    sendmsg("/queue/logstash", ier)
  end # def index

  def IndexEventResponseHandler(msg)
    if msg.code != 0
      puts msg.inspect
    end
  end # def IndexEventResponseHandler

  def run
    start_log_watcher
    super
  end
end

if $0 == __FILE__
  if ARGV.length != 1
    $stderr.puts "Usage: #{$0} configfile"
    exit 1
  end
  Thread::abort_on_exception = true
  configfile = ARGV[0]
  config = YAML.load(File.open(configfile).read())
  agent = Agent.new(config)
  agent.run
end
