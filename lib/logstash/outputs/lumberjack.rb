class LogStash::Outputs::Lumberjack < LogStash::Outputs::Base

  config_name "lumberjack"
  milestone 1

  # list of addresses lumberjack can send to
  config :hosts, :validate => :array, :required => true

  # the port to connect to
  config :port, :validate => :number, :required => true

  # ssl certificate to use
  config :ssl_certificate, :validate => :path, :required => true

  # window size
  config :window_size, :validate => :number, :default => 5000

  public
  def register
    require 'lumberjack/client'
    connect
  end # def register

  public
  def receive(event)
    return unless output?(event)
    begin
      @client.write(
        {
          "line" => event.message, 
          "host" => event.source_host, 
          "file" => event.source_path,
          "type" => event.type
        }.merge(event["@fields"])
      )
    rescue Exception => e
      @logger.error("Client write error", :e => e, :backtrace => e.backtrace)
      connect
      retry
    end
  end # def receive

  private 
  def connect
    @logger.info("Connecting to lumberjack server.", :addresses => @hosts, :port => @port, 
        :ssl_certificate => @ssl_certificate, :window_size => @window_size)
    begin
      @client = Lumberjack::Client.new(:addresses => @hosts, :port => @port, 
        :ssl_certificate => @ssl_certificate, :window_size => @window_size)
    rescue Exception => e
      @logger.error("All hosts unavailable, sleeping", :hosts => @hosts, :e => e, 
        :backtrace => e.backtrace)
      sleep(10)
      retry
    end
  end
end
