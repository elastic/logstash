# Licensed to Elasticsearch B.V. under one or more contributor
# license agreements. See the NOTICE file distributed with
# this work for additional information regarding copyright
# ownership. Elasticsearch B.V. licenses this file to you under
# the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#  http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

require "base64"

module LogStash module Util class CloudSettingId

  def self.cloud_id_encode(*args)
    Base64.urlsafe_encode64(args.join("$"))
  end
  DOT_SEPARATOR = "."
  CLOUD_PORT = "443"

  attr_reader :original, :decoded, :label
  attr_reader :elasticsearch_host, :elasticsearch_scheme, :elasticsearch_port
  attr_reader :kibana_host, :kibana_scheme, :kibana_port
  attr_reader :other_identifiers

  # The constructor is expecting a 'cloud.id', a string in 2 variants.
  # 1 part example: 'dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy'
  # 2 part example: 'foobar:dXMtZWFzdC0xLmF3cy5mb3VuZC5pbyRub3RhcmVhbCRpZGVudGlmaWVy'
  # The two part variant has a 'label' prepended with a colon separator. The label is not encoded.
  # The 1 part (or second section of the 2 part variant) is base64 encoded.
  # The original string before encoding has three segments separated by a dollar sign.
  # e.g. 'us-east-1.aws.found.io$notareal$identifier'
  # The first segment is the cloud base url, e.g. 'us-east-1.aws.found.io'
  # The second segment is the elasticsearch host identifier, e.g. 'notareal'
  # The third segment is the kibana host identifier, e.g. 'identifier'
  # The 'cloud.id' value decoded into the #attr_reader ivars.
  def initialize(value)
    return if value.nil?

    unless value.is_a?(String)
      raise ArgumentError.new("Cloud Id must be String. Received: #{value.class}")
    end
    @original = value
    @label, colon, encoded = @original.partition(":")
    if encoded.empty?
      @decoded = Base64.urlsafe_decode64(@label) rescue ""
      @label = ""
    else
      @decoded = Base64.urlsafe_decode64(encoded) rescue ""
    end

    @decoded = @decoded.encode(Encoding::UTF_8, :invalid => :replace, :undef => :replace)

    if @decoded.count("$") < 2
      raise ArgumentError.new("Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"#{@decoded}\".")
    end

    segments = @decoded.split("$")
    if segments.any?(&:empty?)
      raise ArgumentError.new("Cloud Id, after decoding, is invalid. Format: '<segment1>$<segment2>$<segment3>'. Received: \"#{@decoded}\".")
    end
    cloud_base = segments.shift
    cloud_host = "#{DOT_SEPARATOR}#{cloud_base}"
    cloud_host, cloud_port = cloud_host.split(":")
    cloud_port ||= CLOUD_PORT

    @elasticsearch_host, @kibana_host, *@other_identifiers = segments
    @elasticsearch_host, @elasticsearch_port = @elasticsearch_host.split(":")
    @kibana_host, @kibana_port = @kibana_host.split(":") if @kibana_host
    @elasticsearch_port ||= cloud_port
    @kibana_port ||= cloud_port
    @other_identifiers ||= []

    if @elasticsearch_host == "undefined"
      raise ArgumentError.new("Cloud Id, after decoding, elasticsearch segment is 'undefined', literally.")
    end
    @elasticsearch_scheme = "https"
    @elasticsearch_host.concat(cloud_host)
    @elasticsearch_host.concat(":#{@elasticsearch_port}")

    if @kibana_host == "undefined"
      raise ArgumentError.new("Cloud Id, after decoding, the kibana segment is 'undefined', literally. You may need to enable Kibana in the Cloud UI.")
    end

    @kibana_scheme = "https"
    @kibana_host ||= String.new # non-sense really to have '.my-host:443' but we're mirroring others
    @kibana_host.concat(cloud_host)
    @kibana_host.concat(":#{@kibana_port}")
  end

  def to_s
    @decoded.to_s
  end

  def inspect
    to_s
  end
end end end
