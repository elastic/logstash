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

require "logstash/instrument/metric_type/counter"
require "logstash/instrument/metric_type/gauge"

module LogStash module Instrument
  module MetricType
    METRIC_TYPE_LIST = {
      :counter => LogStash::Instrument::MetricType::Counter,
      :gauge => LogStash::Instrument::MetricType::Gauge
    }.freeze

    # Use the string to generate a concrete class for this metrics
    #
    # @param [String] The name of the class
    # @param [Array] Namespaces list
    # @param [String] The metric key
    # @raise [NameError] If the class is not found
    def self.create(type, namespaces, key)
      METRIC_TYPE_LIST[type].new(namespaces, key)
    end
  end
end; end
