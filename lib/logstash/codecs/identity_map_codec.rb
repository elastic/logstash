# encoding: utf-8
require "logstash/namespace"
require "concurrent"

# This class is a Codec duck type
# Using Composition, it maps from a stream identity to
# a cloned codec instance via the same API as a Codec

module LogStash module Codecs class IdentityMapCodec
  # subclass of Exception, LS has more than limit (100) active streams
  class IdentityMapUpperLimitException < Exception; end

  module EightyPercentWarning
    extend self
    def visit(imc)
      current_size, limit = imc.current_size_and_limit
      return if current_size < (limit * 0.8)
      imc.logger.warn("IdentityMapCodec has reached 80% capacity",
        :current_size => current_size, :upper_limit => limit)
    end
  end

  module UpperLimitReached
    extend self
    def visit(imc)
      current_size, limit = imc.current_size_and_limit
      return if current_size < limit
      current_size, limit = imc.map_cleanup
      return if current_size < limit
      imc.logger.error("IdentityMapCodec has reached 100% capacity",
          :current_size => current_size, :upper_limit => limit)
      raise IdentityMapUpperLimitException.new
    end
  end

  class MapCleaner
    def initialize(imc, interval)
      @running = true
      @imc, @interval = imc, interval
    end

    def run
      @thread = Thread.new(@imc) do |imc|
        loop do
          sleep @interval
          break if !@running
          imc.map_cleanup
        end
      end
      self
    end

    def stop
      @running = false
      @thread.wakeup
    end
  end

  MAX_IDENTITIES = 100
  EVICT_TIMEOUT = 60 * 60 * 4 # 4 hours
  CLEANER_INTERVAL = 60 * 5 # 5 minutes

  attr_reader :identity_map, :usage_map
  attr_accessor :base_codec, :logger, :cleaner

  def initialize(codec, logger)
    @base_codec = codec
    @base_values = [codec]
    @identity_map = Hash.new &method(:codec_builder)
    # @identity_map = Concurrent::Hash.new &method(:codec_builder)
    @usage_map = Hash.new
    # @usage_map = Concurrent::Hash.new
    @logger = logger
    @max_identities = MAX_IDENTITIES
    @evict_timeout = EVICT_TIMEOUT
    @cleaner = MapCleaner.new(self, CLEANER_INTERVAL).run
  end

  def max_identities(max)
    @max_identities = max.to_i.abs
    self
  end

  def evict_timeout(timeout)
    @evict_timeout = timeout.to_i.abs
    self
  end

  def cleaner_interval(interval)
    @cleaner.stop
    @cleaner = MapCleaner.new(self, interval.to_i.abs).run
    self
  end

  def stream_codec(identity)
    return base_codec if identity.nil?
    track_identity_usage(identity)
    identity_map[identity]
  end

  def decode(data, identity = nil, &block)
    stream_codec(identity).decode(data, &block)
  end

  alias_method :<<, :decode

  def encode(event, identity = nil)
    stream_codec(identity).encode(event)
  end

  # this method should not be called from
  # the input or the pipeline
  def flush(&block)
    map_values.each do |codec|
      #let ruby do its default args thing
      block.nil? ? codec.flush : codec.flush(&block)
    end
  end

  def close()
    cleaner.stop
    map_values.each(&:close)
  end

  def map_values
    no_streams? ? @base_values : identity_map.values
  end

  def max_limit
    @max_identities
  end

  def size
    identity_map.size
  end

  # support cleaning of stale codecs
  def map_cleanup
    cut_off = Time.now.to_i
    candidates, rest = usage_map.partition {|identity, timeout| timeout <= cut_off }
    candidates.each do |identity, timeout|
      identity_map.delete(identity).flush
      usage_map.delete(identity)
    end
    current_size_and_limit
  end

  def current_size_and_limit
    [size, max_limit]
  end

  private

  def track_identity_usage(identity)
    check_map_limits
    usage_map.store(identity, eviction_timestamp)
  end

  def eviction_timestamp
    Time.now.to_i + @evict_timeout
  end

  def check_map_limits
    UpperLimitReached.visit(self)
    EightyPercentWarning.visit(self)
  end

  def codec_builder(hash, k)
    codec = hash.empty? ? @base_codec : @base_codec.clone
    hash.store(k, codec)
  end

  def no_streams?
    identity_map.empty?
  end
end end end
