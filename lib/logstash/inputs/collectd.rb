# encoding utf-8
require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "time"

# Read connectd binary protocol as events over the network via udp.
# See https://collectd.org/wiki/index.php/Binary_protocol
#
# A sample collectd.conf to send to logstash might be:
#
#Hostname    "host.example.com"
#LoadPlugin interface
#LoadPlugin load
#LoadPlugin memory
#LoadPlugin network
#<Plugin interface>
#	Interface "eth0"
#	IgnoreSelected false
#</Plugin>
#<Plugin network>
#	<Server "10.0.0.1" "25826">
#	</Server>
#</Plugin>
#

#
class LogStash::Inputs::Collectd < LogStash::Inputs::Base
  config_name "collectd"
  milestone 1

  # The file path to the collectd typesdb to use. Required.
  config :typesdb_path, :validate => :path, :require => true

  # The address to listen on
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on. Collectd defaults to 25826
  config :port, :validate => :number, :default => 25826

  # Buffer size
  config :buffer_size, :validate => :number, :default => 8192

  public
  def initialize(params)
    super
    BasicSocket.do_not_reverse_lookup = true
    @idbyte = 0
    @length = 0
    @typenum = 0
    @cdhost = ''
    @cdtype = ''
    @header = []; @body = []; @line = []
    @collectd = {}
    @typesdb = {}
  end # def initialize

  public
  def register
    @udp = nil
  end # def register

  public
  def run(output_queue)
    begin
      # get typesdb
      get_typesdb(@typesdb_path)
      # collectd server
      collectd_listener(output_queue)
    rescue LogStash::ShutdownSignal
      # do nothing, shutdown was requested.
    rescue => e
      @logger.warn("Collectd listener died", :exception => e, :backtrace => e.backtrace)
      sleep(5)
      retry
    end # begin
  end # def run

  public
  def get_typesdb(path)
    # Get the typesdb
    @logger.info("Getting Collectd typesdb info", :typesdb => "#{path}")
    File.open(path, 'r').each_line do |line|
      typename, *line = line.strip.split
      if typename[0,1] != '#' # Don't process commented lines
      v = line.collect { |l| l.strip.split(":")[0] }
      @typesdb[typename] = v
      end
    end
  end # def get_typesdb

  public
  def type_map(id)
    case id
      when 0; return "host"
      when 2; return "plugin"
      when 3; return "plugin_instance"
      when 4; return "collectd_type"
      when 5; return "type_instance"
      when 6; return "values"
      when 8; return "@timestamp"
    end
  end # def type_map

  public
  def vt_map(id)
    case id
      when 0; return "COUNTER"
      when 1; return "GAUGE"
      when 2; return "DERIVE"
      when 3; return "ABSOLUTE"
      else;   return 'UNKNOWN'
    end
  end

  public
  def get_values(id, body)
    retval = ''
    case id
      when 0,2,3,4,5 # String types
        retval = body.pack("C*")
        retval = retval[0..-2]
      when 8 # Time
        # Time here, in bit-shifted format.  Parse bytes into UTC.
        byte1, byte2 = body.pack("C*").unpack("NN")
        retval = Time.at(( ((byte1 << 32) + byte2) * (2**-30) )).utc
      when 6 # Values
        val_bytes = body.slice!(0..1)
        val_count = val_bytes.pack("C*").unpack("n")
        if body.length % 9 == 0 # Should be 9 fields
          count = 0
          retval = []
          types = body.slice!(0..((body.length/9)-1))
          while body.length > 0
            vtype = vt_map(types[count])
            case types[count]
              when 0, 3; v = body.slice!(0..7).pack("C*").unpack("Q>")[0]
              when 1;    v = body.slice!(0..7).pack("C*").unpack("E")[0]
              when 2;    v = body.slice!(0..7).pack("C*").unpack("q>")[0]
              else;      v = 0
            end
            retval << v
            count += 1
          end
        else
          @logger.error("Incorrect number of data fields for collectd record", :body => body.to_s)
        end
    end
    return retval
  end # def get_values

  private
  def collectd_listener(output_queue)

    @logger.info("Starting Collectd listener", :address => "#{@host}:#{@port}")

    if @udp && ! @udp.closed?
      @udp.close
    end

    @udp = UDPSocket.new(Socket::AF_INET)
    @udp.bind(@host, @port)

    loop do
      payload, client = @udp.recvfrom(@buffer_size)
      payload.each_byte do |byte|
        if @idbyte < 4
          @header << byte
        elsif @idbyte == 4
          @line = @header
          @typenum = (@header[0] << 1) + @header[1]
          @length = (@header[2] << 1) + @header[3]
          @line << byte
          @body << byte
        elsif @idbyte > 4 && @idbyte < @length
          @line << byte
          @body << byte
        end
        if @length > 0 && @idbyte == @length-1
          if @typenum == 0;
            @cdhost = @body.pack("C*")
            @cdhost = @cdhost[0..-2] #=> Trim trailing null char
            @collectd['host'] = @cdhost
          else
            field = type_map(@typenum)
            if @typenum == 4
              @cdtype = get_values(@typenum, @body)
              @collectd['collectd_type'] = @cdtype
            end
            if @typenum == 8
              if @collectd.length > 1
                @collectd.delete_if {|k, v| v == "" }
                if @collectd.has_key?("collectd_type") # This means the full event should be here
                  # As crazy as it sounds, this is where we actually send our events to the queue!
                  # After we've gotten a new timestamp event it means another event is coming, so
                  # we flush the existing one to the queue
                  event = LogStash::Event.new({})
                  @collectd.each {|k, v| event[k] = @collectd[k]}
                  decorate(event)
                  output_queue << event
                end
                @collectd.clear
                @collectd['host'] = @cdhost
                @collectd['collectd_type'] = @cdtype
              end
            end
            values = get_values(@typenum, @body)
            if values.kind_of?(Array)
              if values.length > 1              #=> Only do this iteration on multi-value arrays
                (0..(values.length - 1)).each {|x| @collectd[@typesdb[@collectd['collectd_type']][x]] = values[x]}
              else                              #=> Otherwise it's a single value
                @collectd['value'] = values[0]  #=> So name it 'value' accordingly
              end
            elsif field != ""                         #=> Not an array, make sure it's non-empty
              @collectd[field] = values         #=> Append values to @collectd under key field
            end
          end
          @idbyte = 0; @length = 0; @header.clear; @body.clear; @line.clear  #=> Reset everything
        else
          @idbyte += 1
        end
      end
    end
  ensure
    if @udp
      @udp.close_read rescue nil
      @udp.close_write rescue nil
    end
  end # def collectd_listener

  public
  def teardown
    @udp.close if @udp && !@udp.closed?
  end

end # class LogStash::Inputs::Collectd
