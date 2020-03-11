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

require "logstash/instrument/collector"

module LogStash
  module Api
    class Service
      include LogStash::Util::Loggable

      attr_reader :agent

      def initialize(agent)
        @agent = agent
        logger.debug("[api-service] start") if logger.debug?
      end

      def started?
        true
      end

      def snapshot
        agent.metric.collector.snapshot_metric
      end

      def get_shallow(*path)
        snapshot.metric_store.get_shallow(*path)
      end

      def extract_metrics(path, *keys)
        snapshot.metric_store.extract_metrics(path, *keys)
      end
    end
  end
end
