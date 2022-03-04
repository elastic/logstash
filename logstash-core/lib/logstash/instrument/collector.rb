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

require "logstash/instrument/metric_store"
require "concurrent/timer_task"
require "observer"
require "singleton"
require "thread"

module LogStash module Instrument
  # The Collector is the single point of reference for all
  # the metrics collection inside logstash, the metrics library will make
  # direct calls to this class.
  class Collector
    include LogStash::Util::Loggable

    SNAPSHOT_ROTATION_TIME_SECS = 1 # seconds
    SNAPSHOT_ROTATION_TIMEOUT_INTERVAL_SECS = 10 * 60 # seconds

    attr_accessor :agent

    def initialize
      @metric_store = MetricStore.new
      @agent = nil
    end

    # The metric library will call this unique interface
    # its the job of the collector to update the store with new metric
    # of update the metric
    #
    # If there is a problem with the key or the type of metric we will record an error
    # but we won't stop processing events, theses errors are not considered fatal.
    #
    def push(namespaces_path, key, type, *metric_type_params)
      begin
        get(namespaces_path, key, type).execute(*metric_type_params)
      rescue MetricStore::NamespacesExpectedError => e
        logger.error("Collector: Cannot record metric", :exception => e)
      rescue NameError => e
        logger.error("Collector: Cannot create concrete class for this metric type",
                     :type => type,
                     :namespaces_path => namespaces_path,
                     :key => key,
                     :metrics_params => metric_type_params,
                     :exception => e,
                     :stacktrace => e.backtrace)
      end
    end

    def get(namespaces_path, key, type)
      @metric_store.fetch_or_store(namespaces_path, key) do
        LogStash::Instrument::MetricType.create(type, namespaces_path, key)
      end
    end

    # Snapshot the current Metric Store and return it immediately,
    # This is useful if you want to get access to the current metric store without
    # waiting for a periodic call.
    #
    # @return [LogStash::Instrument::MetricStore]
    def snapshot_metric
      Snapshot.new(@metric_store.dup)
    end

    def clear(keypath)
      @metric_store.prune(keypath)
    end
  end
end; end
