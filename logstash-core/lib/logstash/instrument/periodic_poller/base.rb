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

require "logstash/util"
require "concurrent"

module LogStash module Instrument module PeriodicPoller
  class Base
    include LogStash::Util::Loggable

    DEFAULT_OPTIONS = {
      :polling_interval => 5,
    }

    attr_reader :metric

    public
    def initialize(metric, options = {})
      @metric = metric
      @options = DEFAULT_OPTIONS.merge(options)
      configure_task
    end

    def update(time, result, exception)
      return unless exception

      logger.error("Exception",
              :poller => self,
              :result => result,
              :exception => exception.class,
              :polling_interval => @options[:polling_interval],
              :executed_at => time)
    end

    def collect
      raise NotImplementedError, "#{self.class.name} need to implement `#collect`"
    end

    def start
      logger.debug("Starting",
                   :polling_interval => @options[:polling_interval]) if logger.debug?

      collect # Collect data right away if possible
      @task.execute
    end

    def stop
      logger.debug("Stopping")
      @task.shutdown
    end

    protected
    def configure_task
      @task = Concurrent::TimerTask.new { collect }
      @task.execution_interval = @options[:polling_interval]
      @task.add_observer(self)
    end
  end
end
end; end
