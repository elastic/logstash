# encoding utf-8
require "date"
require "logstash/inputs/base"
require "logstash/namespace"
require "socket"
require "tempfile"
require "time"

# Read events from the connectd binary protocol over the network via udp.
# See https://collectd.org/wiki/index.php/Binary_protocol
#
# Configuration in your Logstash configuration file can be as simple as:
#     input {
#       collectd {}
#     }
#
# A sample collectd.conf to send to Logstash might be:
#
#     Hostname    "host.example.com"
#     LoadPlugin interface
#     LoadPlugin load
#     LoadPlugin memory
#     LoadPlugin network
#     <Plugin interface>
#         Interface "eth0"
#         IgnoreSelected false
#     </Plugin>
#     <Plugin network>
#         <Server "10.0.0.1" "25826">
#         </Server>
#     </Plugin>
#
# Be sure to replace "10.0.0.1" with the IP of your Logstash instance.
#

#
class LogStash::Inputs::Collectd < LogStash::Inputs::Base
  config_name "collectd"
  milestone 1

  AUTHFILEREGEX = /([^:]+): (.+)/
  TYPEMAP = {
      0   => "host",
      1   => "@timestamp",
      2   => "plugin",
      3   => "plugin_instance",
      4   => "collectd_type",
      5   => "type_instance",
      6   => "values",
      7   => "interval",
      8   => "@timestamp",
      9   => "interval",
      256 => "message",
      257 => "severity",
      512 => "signature",
      528 => "encryption"
  }

  SECURITY_NONE = "None"
  SECURITY_SIGN = "Sign"
  SECURITY_ENCR = "Encrypt"

  # File path(s) to collectd types.db to use.
  # The last matching pattern wins if you have identical pattern names in multiple files.
  # If no types.db is provided the included types.db will be used (currently 5.4.0).
  config :typesdb, :validate => :array

  # The address to listen on.  Defaults to all available addresses.
  config :host, :validate => :string, :default => "0.0.0.0"

  # The port to listen on.  Defaults to the collectd expected port of 25826.
  config :port, :validate => :number, :default => 25826

  # Prune interval records.  Defaults to true.
  config :prune_intervals, :validate => :boolean, :default => true

  # Buffer size. 1452 is the collectd default for v5+
  config :buffer_size, :validate => :number, :default => 1452

  # Security Level. Default is "None". This setting mirrors the setting from the
  # collectd [Network plugin](https://collectd.org/wiki/index.php/Plugin:Network)
  config :security_level, :validate => [SECURITY_NONE, SECURITY_SIGN, SECURITY_ENCR],
    :default => "None"

  # Path to the authentication file. This file should have the same format as
  # the [AuthFile](http://collectd.org/documentation/manpages/collectd.conf.5.shtml#authfile_filename)
  # in collectd. You only need to set this option if the security_level is set to
  # "Sign" or "Encrypt"
  config :authfile, :validate => :string

  # What to do when a value in the event is NaN (Not a Number)
  # - change_value (default): Change the NaN to the value of the nan_value option and add nan_tag as a tag
  # - warn: Change the NaN to the value of the nan_value option, print a warning to the log and add nan_tag as a tag
  # - drop: Drop the event containing the NaN (this only drops the single event, not the whole packet)
  config :nan_handeling, :validate => ['change_value','warn','drop'],
    :default => 'change_value'

  # Only relevant when nan_handeling is set to 'change_value'
  # Change NaN to this configured value
  config :nan_value, :validate => :number, :default => 0

  # The tag to add to the event if a NaN value was found
  # Set this to an empty string ('') if you don't want to tag
  config :nan_tag, :validate => :string, :default => '_collectdNaN'

  public
  def initialize(params)
    super
    BasicSocket.do_not_reverse_lookup = true
    @timestamp = Time.now().utc
    @collectd = {}
    @types = {}
  end # def initialize

  public
  def register
    @udp = nil
    if @typesdb.nil?
      @typesdb = LogStash::Environment.vendor_path("collectd/types.db")
      if !File.exists?(@typesdb)
        raise "You must specify 'typesdb => ...' in your collectd input (I looked for '#{@typesdb}')"
      end
      @logger.info("Using internal types.db", :typesdb => @typesdb.to_s)
    end

    if ([SECURITY_SIGN, SECURITY_ENCR].include?(@security_level))
      if @authfile.nil?
        raise "Security level is set to #{@security_level}, but no authfile was configured"
      else
        # Load OpenSSL and instantiate Digest and Crypto functions
        require 'openssl'
        @sha256 = OpenSSL::Digest::Digest.new('sha256')
        @sha1 = OpenSSL::Digest::Digest.new('sha1')
        @cipher = OpenSSL::Cipher.new('AES-256-OFB')
        @auth = {}
        parse_authfile
      end
    end
  end # def register

  public
  def run(output_queue)
    begin
      # get types
      get_types(@typesdb)
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
  def get_types(paths)
    # Get the typesdb
    paths = Array(paths) # Make sure a single path is still forced into an array type
    paths.each do |path|
      @logger.info("Getting Collectd typesdb info", :typesdb => path.to_s)
      File.open(path, 'r').each_line do |line|
        typename, *line = line.strip.split
        next if typename.nil? || if typename[0,1] != '#' # Don't process commented or blank lines
          v = line.collect { |l| l.strip.split(":")[0] }
          @types[typename] = v
        end
      end
    end
  @logger.debug("Collectd Types", :types => @types.to_s)
  end # def get_types

  public
  def get_values(id, body)
    retval = ''
    case id
      when 0,2,3,4,5,256 #=> String types
        retval = body.pack("C*")
        retval = retval[0..-2]
      when 1 # Time
        # Time here, in bit-shifted format.  Parse bytes into UTC.
        byte1, byte2 = body.pack("C*").unpack("NN")
        retval = Time.at(( ((byte1 << 32) + byte2))).utc
      when 7,257 #=> Numeric types
        retval = body.slice!(0..7).pack("C*").unpack("E")[0]
      when 8 # Time, Hi-Res
        # Time here, in bit-shifted format.  Parse bytes into UTC.
        byte1, byte2 = body.pack("C*").unpack("NN")
        retval = Time.at(( ((byte1 << 32) + byte2) * (2**-30) )).utc
      when 9 # Interval, Hi-Res
        byte1, byte2 = body.pack("C*").unpack("NN")
        retval = (((byte1 << 32) + byte2) * (2**-30)).to_i
      when 6 # Values
        val_bytes = body.slice!(0..1)
        val_count = val_bytes.pack("C*").unpack("n")
        if body.length % 9 == 0 # Should be 9 fields
          count = 0
          retval = []
          types = body.slice!(0..((body.length/9)-1))
          while body.length > 0
            # TYPE VALUES:
            # 0: COUNTER
            # 1: GAUGE
            # 2: DERIVE
            # 3: ABSOLUTE
            case types[count]
              when 1;
                v = body.slice!(0..7).pack("C*").unpack("E")[0]
                if v.nan?
                  case @nan_handeling
                  when 'drop'; return false
                  else
                    v = @nan_value
                    add_tag(@nan_tag)
                    @nan_handeling == 'warn' && @logger.warn("NaN in (unfinished event) #{@collectd}")
                  end
                end
              when 0, 3; v = body.slice!(0..7).pack("C*").unpack("Q>")[0]
              when 2;    v = body.slice!(0..7).pack("C*").unpack("q>")[0]
              else;      v = 0
            end
            retval << v
            count += 1
          end
        else
          @logger.error("Incorrect number of data fields for collectd record", :body => body.to_s)
        end
      when 512 # signature
        if body.length < 32
          @logger.warning("SHA256 signature too small (got #{body.length} bytes instead of 32)")
        elsif body.length < 33
          @logger.warning("Received signature without username")
        else
          retval = []
          # Byte 32 till the end contains the username as chars (=unsigned ints)
          retval << body[32..-1].pack('C*')
          # Byte 0 till 31 contain the signature
          retval << body[0..31].pack('C*')
        end
      when 528 # encryption
        retval = []
        user_length = (body.slice!(0) << 8) + body.slice!(0)
        retval << body.slice!(0..user_length-1).pack('C*') # Username
        retval << body.slice!(0..15).pack('C*')            # IV
        retval << body.pack('C*')                          # Encrypted content
    end
    return retval
  end # def get_values

  private
  def parse_authfile
    # We keep the authfile parsed in memory so we don't have to open the file
    # for every event.
    @logger.debug("Parsing authfile #{@authfile}")
    if !File.exist?(@authfile)
      raise "The file #{@authfile} was not found"
    end
    @auth.clear
    @authmtime = File.stat(@authfile).mtime
    File.readlines(@authfile).each do |line|
      #line.chomp!
      k,v = line.scan(AUTHFILEREGEX).flatten
      if k and v
        @logger.debug("Added authfile entry '#{k}' with key '#{v}'")
        @auth[k] = v
      else
        @logger.info("Ignoring malformed authfile line '#{line.chomp}'")
      end
    end
  end # def parse_authfile

  private
  def get_key(user)
    return if @authmtime.nil? or @authfile.nil?
    # Validate that our auth data is still up-to-date
    parse_authfile if @authmtime < File.stat(@authfile).mtime
    key = @auth[user]
    @logger.warn("User #{user} is not found in the authfile #{@authfile}") if key.nil?
    return key
  end # def get_key

  private
  def verify_signature(user, signature, payload)
    # The user doesn't care about the security
    return true if @security_level == SECURITY_NONE

    # We probably got and array of ints, pack it!
    payload = payload.pack('C*') if payload.is_a?(Array)

    key = get_key(user)
    return false if key.nil?

    return true if OpenSSL::HMAC.digest(@sha256, key, user+payload) == signature
    return false
  end # def verify_signature

  private
  def decrypt_packet(user, iv, content)
    # Content has to have at least a SHA1 hash (20 bytes), a header (4 bytes) and
    # one byte of data
    return [] if content.length < 26
    content = content.pack('C*') if content.is_a?(Array)
    key = get_key(user)
    return [] if key.nil?

    # Set the correct state of the cipher instance
    @cipher.decrypt
    @cipher.padding = 0
    @cipher.iv = iv
    @cipher.key = @sha256.digest(key);
    # Decrypt the content
    plaintext = @cipher.update(content) + @cipher.final
    # Reset the state, as adding a new key to an already instantiated state
    # results in an exception
    @cipher.reset

    # The plaintext contains a SHA1 hash as checksum in the first 160 bits
    # (20 octets) of the rest of the data
    hash = plaintext.slice!(0..19)

    if @sha1.digest(plaintext) != hash
      @logger.warn("Unable to decrypt packet, checksum mismatch")
      return []
    end
    return plaintext.unpack('C*')
  end # def decrypt_packet

  private
  def generate_event(output_queue)
    # Prune these *specific* keys if they exist and are empty.
    # This is better than looping over all keys every time.
    @collectd.delete('type_instance') if @collectd['type_instance'] == ""
    @collectd.delete('plugin_instance') if @collectd['plugin_instance'] == ""
    # As crazy as it sounds, this is where we actually send our events to the queue!
    event = LogStash::Event.new
    @collectd.each {|k, v| event[k] = @collectd[k]}
    decorate(event)
    output_queue << event
  end # def generate_event

  private
  def clean_up()
    @collectd.each_key do |k|
      @collectd.delete(k) if !['host','collectd_type', 'plugin', 'plugin_instance', '@timestamp', 'type_instance'].include?(k)
    end
  end # def clean_up

  private
  def add_tag(new_tag)
    return if new_tag.empty?
    @collectd['tags'] ||= []
    @collectd['tags'] << new_tag
  end

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
      payload = payload.bytes.to_a

      # Clear the last event
      @collectd.clear
      was_encrypted = false

      while payload.length > 0 do
        typenum = (payload.slice!(0) << 8) + payload.slice!(0)
        # Get the length of the data in this part, but take into account that
        # the header is 4 bytes
        length  = ((payload.slice!(0) << 8) + payload.slice!(0)) - 4

        if length > payload.length
          @logger.info("Header indicated #{length} bytes will follow, but packet has only #{payload.length} bytes left")
          break
        end
        body = payload.slice!(0..length-1)

        field = TYPEMAP[typenum]
        if field.nil?
          @logger.warn("Unknown typenumber: #{typenum}")
          next
        end

        values = get_values(typenum, body)

        case field
        when "signature"
          break if !verify_signature(values[0], values[1], payload)
          next
        when "encryption"
          payload = decrypt_packet(values[0], values[1], values[2])
          # decrypt_packet returns an empty array if the decryption was
          # unsuccessful and this inner loop checks the length. So we can safely
          # set the 'was_encrypted' variable.
          was_encrypted=true
          next
        when "plugin"
          # We've reached a new plugin, delete everything except for the the host
          # field, because there's only one per packet and the timestamp field,
          # because that one goes in front of the plugin
          @collectd.each_key do |k|
            @collectd.delete(k) if !['host', '@timestamp'].include?(k)
          end
        when "collectd_type"
          # We've reached a new type within the plugin section, delete all fields
          # that could have something to do with the previous type (if any)
          @collectd.each_key do |k|
            @collectd.delete(k) if !['host', '@timestamp', 'plugin', 'plugin_instance'].include?(k)
          end
        end

        break if !was_encrypted and @security_level == SECURITY_ENCR

        # Fill in the fields.
        if values.kind_of?(Array)
          if values.length > 1              # Only do this iteration on multi-value arrays
            values.each_with_index {|value, x| @collectd[@types[@collectd['collectd_type']][x]] = values[x]}
          else                              # Otherwise it's a single value
            @collectd['value'] = values[0]      # So name it 'value' accordingly
          end
        elsif !values
          clean_up()
          next
        elsif field != nil                  # Not an array, make sure it's non-empty
          @collectd[field] = values            # Append values to @collectd under key field
        end

        if ["interval", "values"].include?(field)
          if ((@prune_intervals && ![7,9].include?(typenum)) || !@prune_intervals)
            generate_event(output_queue)
          end
          clean_up()
        end
      end # while payload.length > 0 do
    end # loop do

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
