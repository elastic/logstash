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

require "logstash/plugin"

# This is the base class for logstash codecs.
module LogStash::Codecs; class Base < LogStash::Plugin
  include LogStash::Config::Mixin

  config_name "codec"

  def self.plugin_type
    "codec"
  end

  def initialize(params = {})
    super
    config_init(@params)
    register if respond_to?(:register)
    setup_multi_encode!
  end

  public
  def decode(data)
    raise "#{self.class}#decode must be overidden"
  end # def decode

  alias_method :<<, :decode

  public
  # DEPRECATED: Prefer defining encode_sync or multi_encode
  def encode(event)
    encoded = multi_encode([event])
    encoded.each {|event, data| @on_event.call(event, data) }
  end # def encode

  public
  # Relies on the codec being synchronous (which they all are!)
  # We need a better long term design here, but this is an improvement
  # over the current API for shared plugins
  # It is best if the codec implements this directly
  def multi_encode(events)
    if @has_encode_sync
      events.map {|event| [event, self.encode_sync(event)]}
    else
      batch = Thread.current[:logstash_output_codec_batch] ||= []
      batch.clear

      events.each {|event| self.encode(event) }
      batch
    end
  end

  def setup_multi_encode!
    @has_encode_sync = self.methods.include?(:encode_sync)

    on_event do |event, data|
      Thread.current[:logstash_output_codec_batch] << [event, data]
    end
  end

  public
  def close; end;

  # @param block [Proc(event, data)] the callback proc passing the original event and the encoded event
  public
  def on_event(&block)
    @on_event = block
  end

  public
  def flush(&block)
    # does nothing by default.
    # if your codec needs a flush method (like you are spooling things)
    # you must implement this.
  end

  public
  def clone(*args)
    LogStash::Plugins::Contextualizer.initialize_plugin(execution_context, self.class, params).tap do |klone|
      klone.metric = @metric if klone.instance_variable_get(:@metric).nil?
    end
  end
end; end # class LogStash::Codecs::Base
