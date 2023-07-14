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

require 'logstash/instrument/periodic_poller/base'

module LogStash module Instrument module PeriodicPoller
  class FlowRate < Base
    def initialize(metric, agent, options = {})
      super(metric, options)
      @metric = metric
      @agent = agent
    end

    def collect
      @agent.capture_flow_metrics

      pipelines = @agent.running_user_defined_pipelines
      pipelines.values.compact.each(&:collect_flow_metrics)
    end
  end
end end end
