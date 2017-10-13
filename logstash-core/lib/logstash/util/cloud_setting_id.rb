# encoding: utf-8
require "logstash/namespace"
require "base64"

module LogStash module Util class CloudSettingId

  def self.cloud_id_encode(*args)
    Base64.urlsafe_encode64(args.join("$"))
  end
  DOT_SEPARATOR = "."
  CLOUD_PORT = ":443"

  attr_reader :original, :decoded, :label, :elasticsearch_host, :elasticsearch_scheme, :kibana_host, :kibana_scheme

  def initialize(value)
    return if value.nil?

    unless value.is_a?(String)
      raise ArgumentError.new("Cloud Id must be String. Received: #{value.class}")
    end
    @original = value
    @label, sep, last = @original.partition(":")
    if last.empty?
      @decoded = Base64.urlsafe_decode64(@label) rescue ""
      @label = ""
    else
      @decoded = Base64.urlsafe_decode64(last) rescue ""
    end

    @decoded = @decoded.encode(Encoding::UTF_8, :invalid => :replace, :undef => :replace)

    unless @decoded.count("$") == 2
      raise ArgumentError.new("Cloud Id does not decode. You may need to enable Kibana in the Cloud UI. Received: \"#{@decoded}\".")
    end

    segments = @decoded.split("$")
    if segments.any?(&:empty?)
      raise ArgumentError.new("Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"#{@decoded}\".")
    end

    cloud_host = segments.shift.prepend(DOT_SEPARATOR).concat(CLOUD_PORT)
    @elasticsearch_host, @kibana_host = segments

    if @elasticsearch_host == "undefined"
      raise ArgumentError.new("Cloud Id, after decoding, elasticsearch segment is 'undefined', literally.")
    end
    @elasticsearch_scheme = "https"
    @elasticsearch_host.concat(cloud_host)

    if @kibana_host == "undefined"
      raise ArgumentError.new("Cloud Id, after decoding, the kibana segment is 'undefined', literally. You may need to enable Kibana in the Cloud UI.")
    end
    @kibana_scheme = "https"
    @kibana_host.concat(cloud_host)
  end

  def to_s
    @decoded.to_s
  end

  def inspect
    to_s
  end
end end end