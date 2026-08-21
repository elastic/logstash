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

require "concurrent"

module LogStash
  # Runs a block every `execution_interval` seconds, notifying observers via
  # `update(time, result, exception)`. If a run exceeds `timeout_interval` the
  # observer receives a `Concurrent::TimeoutError`. A timed-out run is abandoned
  # rather than killed; while it is still executing no new run is started, so at
  # most one run is ever in flight.
  #
  # Replaces `Concurrent::TimerTask`, whose per-run timeout was removed in
  # concurrent-ruby 1.1.10.
  class TimerTask
    attr_accessor :execution_interval, :timeout_interval

    def initialize(opts = {}, &block)
      raise ArgumentError, "no block given" unless block_given?

      @execution_interval = opts[:execution_interval] || 60
      @timeout_interval = opts[:timeout_interval]
      @task = block
      @observers = []
      @observers_mutex = Mutex.new
      @running = Concurrent::AtomicBoolean.new(false)
      @in_flight = nil # Future reference to executing block
    end

    def add_observer(observer)
      @observers_mutex.synchronize { @observers << observer }
      observer
    end

    def execute
      return self unless @running.make_true

      @driver = Concurrent::TimerTask.new(:execution_interval => @execution_interval) { run_once }
      @driver.execute
      self
    end

    def shutdown
      return false unless @running.make_false

      @driver.shutdown if @driver
      true
    end

    private

    def run_once
      # A prior run timed out and is still executing: keep signalling the timeout
      # but don't pile up a second concurrent run.
      if @in_flight && !@in_flight.complete?
        notify_observers(Time.now, nil, Concurrent::TimeoutError.new)
        return
      end

      future = Concurrent::Future.execute(&@task)
      @in_flight = future
      future.wait(@timeout_interval)

      if !future.complete?
        notify_observers(Time.now, nil, Concurrent::TimeoutError.new)
      elsif future.rejected?
        notify_observers(Time.now, nil, future.reason)
      else
        notify_observers(Time.now, future.value, nil)
      end
    end

    def notify_observers(time, result, exception)
      @observers_mutex.synchronize { @observers.dup }.each do |observer|
        observer.update(time, result, exception)
      end
    end
  end
end
