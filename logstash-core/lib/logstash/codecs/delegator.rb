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

module LogStash::Codecs
  class Delegator < SimpleDelegator
    def initialize(obj)
      super(obj)
      @encode_metric = LogStash::Instrument::NamespacedNullMetric.new
      @decode_metric = LogStash::Instrument::NamespacedNullMetric.new
    end

    def class
      __getobj__.class
    end

    def metric=(metric)
      __getobj__.metric = metric

      __getobj__.metric.gauge(:name, __getobj__.class.config_name)

      @encode_metric = __getobj__.metric.namespace(:encode)
      @encode_metric.counter(:writes_in)
      @encode_metric.timer(:duration_in_millis)

      @decode_metric = __getobj__.metric.namespace(:decode)
      @decode_metric.counter(:writes_in)
      @decode_metric.counter(:out)
      @decode_metric.timer(:duration_in_millis)
    end

    def encode(event)
      @encode_metric.increment(:writes_in)
      @encode_metric.time(:duration_in_millis) do
        __getobj__.encode(event)
      end
    end

    def multi_encode(events)
      @encode_metric.increment(:writes_in, events.length)
      @encode_metric.time(:duration_in_millis) do
        __getobj__.multi_encode(events)
      end
    end

    def decode(data)
      @decode_metric.increment(:writes_in)
      @decode_metric.time(:duration_in_millis) do
        __getobj__.decode(data) do |event|
          @decode_metric.increment(:out)
          yield event
        end
      end
    end
  end
end
