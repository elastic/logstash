# encoding: utf-8
require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"

# Read messages as events over the network via udp. The only required
# configuration item is `port`, which specifies the udp port logstash 
# will listen on for event streams.
#
class LogStash::Inputs::Udp < LogStash::Inputs::Base
  config_name "udp"
  milestone 2

  default :codec, "plain"

  # The address which logstash will listen on.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port which logstash will listen on. Remember that ports less
  # than 1024 (privileged ports) may require root or elevated privileges to use.
  config :port, :validate => :number, :required => true

  # The maximum packet size to read from the network
  config :buffer_size, :validate => :number, :default => 8192
  
  # Number of threads processing packets
  config :workers, :validate => :number, :default => 2
  
  # This is the number of unprocessed UDP packets you can hold in memory
  # before packets will start dropping.
  config :queue_size, :validate => :number, :default => 2000

  public
  def initialize(params)
    super
    BasicSocket.do_not_reverse_lookup = true
  end # def initialize

  public
  def register
    @udp = nil
  end # def register

  public
  def run(output_queue)
	@output_queue = output_queue
    begin
      # udp server
      udp_listener(output_queue)
    rescue LogStash::ShutdownSignal
      # do nothing, shutdown was requested.
    rescue => e
      @logger.warn("UDP listener died", :exception => e, :backtrace => e.backtrace)
      sleep(5)
      retry
    end # begin
  end # def run

  private
  def udp_listener(output_queue)
    @logger.info("Starting UDP listener", :address => "#{@host}:#{@port}")

    if @udp && ! @udp.closed?
      @udp.close
    end

    @udp = UDPSocket.new(Socket::AF_INET)
    @udp.bind(@host, @port)

	  @input_to_worker = SizedQueue.new(@queue_size)

	  @input_workers = @workers.times do |i|
  	    @logger.debug("Starting UDP worker thread", :worker => i)
 		  Thread.new { inputworker(i) }
	  end
	
    loop do
		  #collect datagram message and add to queue
      payload, client = @udp.recvfrom(@buffer_size)
	    @input_to_worker.push([payload,client])
    end
  ensure
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
  end # def udp_listener
  
  def inputworker(number)
    LogStash::Util::set_thread_name("<udp.#{number}")
    begin
      while true
        payload,client = @input_to_worker.pop
		    if payload == LogStash::ShutdownSignal
          @input_to_worker.push(work)
          break
        end

		    @codec.decode(payload) do |event|
          decorate(event)
          event["host"] ||= client[3]
		      @output_queue.push(event)
		    end
      end

    rescue => e
      @logger.error("Exception in inputworker", "exception" => e, "backtrace" => e.backtrace)
    end
  end # def inputworker
  
  public
  def teardown
    @udp.close if @udp && !@udp.closed?
  end

end # class LogStash::Inputs::Udp
