require "logstash/outputs/base"
require "logstash/namespace"

# A plugin for a newly developed Java/Spring Metrics application
# I didn't really want to code this project but I couldn't find
# a respectable alternative that would also run on any Windows
# machine - which is the problem and why I am not going with Graphite
# and statsd.  This application provides multiple integration options
# so as to make its use under your network requirements possible. 
# This includes a REST option that is always enabled for your use
# in case you want to write a small script to send the occasional 
# metric data. 
#
# Find GraphTastic here : https://github.com/NickPadilla/GraphTastic
class LogStash::Outputs::GraphTastic < LogStash::Outputs::Base
  
  config_name "graphtastic"
  milestone 2
  
  # options are udp(fastest - default) - rmi(faster) - rest(fast) - tcp(don't use TCP yet - some problems - errors out on linux)
  config :integration, :validate => ["udp","tcp","rmi","rest"], :default => "udp"
  
  # if using rest as your end point you need to also provide the application url
  # it defaults to localhost/graphtastic.  You can customize the application url
  # by changing the name of the .war file.  There are other ways to change the 
  # application context, but they vary depending on the Application Server in use.
  # Please consult your application server documentation for more on application
  # contexts.
  config :context, :validate => :string, :default => "graphtastic"
  
  # metrics hash - you will provide a name for your metric and the metric 
  # data as key value pairs.  so for example:
  #
  # metrics => { "Response" => "%{response}" } 
  #
  # example for the logstash config
  #
  # metrics => [ "Response", "%{response}" ]
  #
  # NOTE: you can also use the dynamic fields for the key value as well as the actual value
  config :metrics, :validate => :hash, :default => {}
   
  # host for the graphtastic server - defaults to 127.0.0.1
  config :host, :validate => :string, :default => "127.0.0.1"
  
  # port for the graphtastic instance - defaults to 1199 for RMI, 1299 for TCP, 1399 for UDP, and 8080 for REST
  config :port, :validate => :number
  
  # number of attempted retry after send error - currently only way to integrate
  # errored transactions - should try and save to a file or later consumption
  # either by graphtastic utility or by this program after connectivity is
  # ensured to be established. 
  config :retries, :validate => :number, :default => 1
  
  # the number of metrics to send to GraphTastic at one time. 60 seems to be the perfect 
  # amount for UDP, with default packet size. 
  config :batch_number, :validate => :number, :default => 60
  
  # setting allows you to specify where we save errored transactions
  # this makes the most sense at this point - will need to decide
  # on how we reintegrate these error metrics
  # NOT IMPLEMENTED!
  config :error_file, :validate => :string, :default => ""
  
  public
   def register
     @batch = []
     begin
       if @integration.downcase == "rmi"
         if RUBY_ENGINE != "jruby"
            raise Exception.new("LogStash::Outputs::GraphTastic# JRuby is needed for RMI to work!")
         end
         require "java"
         if @port.nil?
           @port = 1199
         end
         registry = java.rmi.registry.LocateRegistry.getRegistry(@host, @port);
         @remote = registry.lookup("RmiMetricService")
       elsif @integration.downcase == "rest"
         require "net/http"         
         if @port.nil?
           @port = 8080
           gem "mail" #outputs/email, # License: MIT License
         end
         @http = Net::HTTP.new(@host, @port)
       end
       @logger.info("GraphTastic Output Successfully Registered! Using #{@integration} Integration!")
     rescue 
       @logger.error("*******ERROR :  #{$!}")
     end
   end

  public
  def receive(event)
    return unless output?(event)
    # Set Intersection - returns a new array with the items that are the same between the two
    if !@tags.empty? && (event.tags & @tags).size == 0
       # Skip events that have no tags in common with what we were configured
       @logger.debug("No Tags match for GraphTastic Output!")
       return
    end
    @retry = 1
    @logger.debug("Event found for GraphTastic!", :tags => @tags, :event => event)
    @metrics.each do |name, metric|
      postMetric(event.sprintf(name),event.sprintf(metric),(event.unix_timestamp*1000))# unix_timestamp is what I need in seconds - multiply by 1000 to make milliseconds.
    end
  end
  
  def postMetric(name, metric, timestamp)
    message = name+","+metric+","+timestamp.to_s
    if @batch.length < @batch_number
      @batch.push(message)
    else
      flushMetrics()      
    end    
  end
  
  def flushMetrics()
    begin
      if @integration.downcase == "tcp"
        flushViaTCP()
      elsif @integration.downcase == "rmi"
        flushViaRMI() 
      elsif @integration.downcase == "udp"
        flushViaUDP()
      elsif @integration.downcase == "rest"
        flushViaREST()
      else
        @logger.error("GraphTastic Not Able To Find Correct Integration - Nothing Sent - Integration Type : ", :@integration => @integration)
      end
      @batch.clear
    rescue
      @logger.error("*******ERROR :  #{$!}")
      @logger.info("*******Attempting #{@retry} out of #{@retries}")
      while @retry < @retries
        @retry = @retry + 1
        flushMetrics()
      end
    end
  end
  
  # send metrics via udp
  def flushViaUDP()
    if @port.nil?
     @port = 1399
    end
    udpsocket.send(@batch.join(','), 0, @host, @port)
    @logger.debug("GraphTastic Sent Message Using UDP : #{@batch.join(',')}")
  end
  
  # send metrics via REST
  def flushViaREST()
    request = Net::HTTP::Put.new("/#{@context}/addMetric/#{@batch.join(',')}")
    response = @http.request(request)
    if response == 'ERROR'
      raise 'Error happend when sending metric to GraphTastic using REST!'
    end
    @logger.debug("GraphTastic Sent Message Using REST : #{@batch.join(',')}", :response => response.inspect)    
  end
  
  # send metrics via RMI
  def flushViaRMI()
    if RUBY_ENGINE != "jruby"
       raise Exception.new("LogStash::Outputs::GraphTastic# JRuby is needed for RMI to work!")
    end
    @remote.insertMetrics(@batch.join(','))
    @logger.debug("GraphTastic Sent Message Using RMI : #{@batch.join(',')}")
  end
  
  # send metrics via tcp
  def flushViaTCP()
    # to correctly read the line we need to ensure we send \r\n at the end of every message.
    if @port.nil?
      @port = 1299
    end
    tcpsocket = TCPSocket.open(@host, @port)
    tcpsocket.send(@batch.join(',')+"\r\n", 0)
    tcpsocket.close
    @logger.debug("GraphTastic Sent Message Using TCP : #{@batch.join(',')}")
  end

  def udpsocket; @socket ||= UDPSocket.new end
  
end