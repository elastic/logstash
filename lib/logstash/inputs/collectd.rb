# encoding utf-8
require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "time"

# Read connectd binary protocol as events over the network via udp.
# See https://collectd.org/wiki/index.php/Binary_protocol
#
class LogStash::Inputs::Collectd < LogStash::Inputs::Base
  config_name "collectd"
  milestone 1

  default :codec, "noop"

  # The file path to the collectd typesdb to use. Required.
  config :typesdb_path, :validate => :string, :require => true

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
    @i = 0
    @l = 0
    @c = 0
    @t = 0
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
      line = line.strip.split
      if line[0] != '#' # Don't process commented lines
        tmp = line.slice!(0)
        v = []
        for entry in line
          v << entry.strip.split(':')[0]
        end
        @typesdb[tmp] = v
      end
    end
  end # def get_typesdb

  public
  def type_map(id)
    retval = ''
    case id
      when 0
        retval = "host"
      when 2
        retval = "plugin"
      when 3
        retval = "plugin_instance"
      when 4
        retval = "collectd_type"
      when 5
        retval = "type_instance"
      when 6
        retval = "values"
      when 8
        retval = "@timestamp"
    end
    return retval
  end # def type_map

  public
  def vt_map(id)
    retval = 'UNKNOWN'
    case id
      when 0
        retval = "COUNTER"
      when 1
        retval = "GAUGE"
      when 2
        retval = "DERIVE"
      when 3
        retval = "ABSOLUTE"
    end
    return retval
  end

  public
  def get_values(id, length, body)
    l = length - 4 # shorten according to the header
    string_type = [ 0, 2, 3, 4, 5 ]
    retval = ''
    case id
      when *string_type
        retval = body.map {|x| x.chr}.join
        retval = retval[0..-2]
      when 8
        i1, i2 = body.pack("C*").unpack("NN")
        retval = Time.at(( ((i1 << 32) + i2) * (2**-30) )).iso8601
      when 6
        val_bytes = body.slice!(0..1)
        val_count = val_bytes.pack("C*").unpack("n")
        if body.length % 9 == 0
          i = 0
          retval = []
          types = body.slice!(0..((body.length/9)-1))
          while body.length > 0
            vtype = vt_map(types[i])
            unsigned = [ 0, 3 ]
            case types[i]
              when *unsigned
                v = body.slice!(0..7).pack("C*").unpack("Q>")[0]
              when 2
                v = body.slice!(0..7).pack("C*").unpack("q>")[0]
              when 1
                v = body.slice!(0..7).pack("C*").unpack("E")[0]
              else
                v = 0
            end
            retval << v
            i += 1
          end
        else
          @logger.error("Incorrect number of data fields for collectd record", :body => "#{body}")
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
        if @i < 4
          @header << byte
        elsif @i == 4
          @line = @header
          @t = (@header[0] << 1) + @header[1]
          @l = (@header[2] << 1) + @header[3]
          @line << byte
          @body << byte
        elsif @i > 4 && @i < @l
          @line << byte
          @body << byte
        end
        if @l > 0 && @i == @l-1
          if @t == 0;
            @cdhost = @body.map {|x| x.chr}.join
            @cdhost = @cdhost[0..-2] #=> Trim trailing null char
            @collectd['host'] = @cdhost
          else
            fname = type_map(@t)
            if @t == 4
              @cdtype = get_values(@t, @l, @body)
              @collectd['collectd_type'] = @cdtype
            end
            if @t == 8
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
            values = get_values(@t, @l, @body)
            if values.kind_of?(Array)
              if values.length > 1              #=> Only do this iteration on multi-value arrays
                (0..(values.length - 1)).each {|x| @collectd[@typesdb[@collectd['collectd_type']][x]] = values[x]}
              else                              #=> Otherwise it's a single value
                @collectd['value'] = values[0]  #=> So name it 'value' accordingly
              end
            elsif fname != ""                 	#=> Not an array, make sure it's non-empty
              @collectd[fname] = values         #=> Append values to @collectd under key fname
            end
          end
          @i = 0; @l = 0; @header.clear; @body.clear; @line.clear  #=> Reset everything
        else
          @i += 1
        end
        @c += 1
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
