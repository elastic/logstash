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

require "logstash/instrument/periodic_poller/dlq"
require "logstash/instrument/periodic_poller/os"
require "logstash/instrument/periodic_poller/jvm"
require "logstash/instrument/periodic_poller/pq"
require "logstash/instrument/periodic_poller/flow_rate"

module LogStash module Instrument
  # Each PeriodPoller manager his own thread to do the poller
  # of the stats, this class encapsulate the starting and stopping of the poller
  # if the unique timer uses too much resource we can refactor this behavior here.
  class PeriodicPollers
    attr_reader :metric

    def initialize(metric, queue_type, agent)
      @metric = metric
      @periodic_pollers = [PeriodicPoller::Os.new(metric),
                           PeriodicPoller::JVM.new(metric),
                           PeriodicPoller::PersistentQueue.new(metric, queue_type, agent),
                           PeriodicPoller::DeadLetterQueue.new(metric, agent),
                           PeriodicPoller::FlowRate.new(metric, agent)]
    end

    def start
      @periodic_pollers.map(&:start)
    end

    def stop
      @periodic_pollers.map(&:stop)
    end
  end
end; end
