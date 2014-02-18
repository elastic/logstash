# encoding: utf-8
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

    @codec.on_event do |payload|
      begin
        @client.write({ 'line' => payload })
      rescue Exception => e
        @logger.error("Client write error, trying connect", :e => e, :backtrace => e.backtrace)
        connect
        retry
      end # begin
    end # @codec
  end # def register

  public
  def receive(event)
    return unless output?(event)
    if event == LogStash::SHUTDOWN
      finished
      return
    end # LogStash::SHUTDOWN
    @codec.encode(event)
  end # def receive

  private 
  def connect
    require 'resolv'
    @logger.info("Connecting to lumberjack server.", :addresses => @hosts, :port => @port, 
        :ssl_certificate => @ssl_certificate, :window_size => @window_size)
    begin
      ips = []
      @hosts.each { |host| ips += Resolv.getaddresses host }
      @client = Lumberjack::Client.new(:addresses => ips.uniq, :port => @port, 
        :ssl_certificate => @ssl_certificate, :window_size => @window_size)
    rescue Exception => e
      @logger.error("All hosts unavailable, sleeping", :hosts => ips.uniq, :e => e, 
        :backtrace => e.backtrace)
      sleep(10)
      retry
    end
  end
end
