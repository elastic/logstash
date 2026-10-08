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

module ::LogStash; module Plugins; module Builtin; module Pipeline; class Input < ::LogStash::Inputs::Base
  include org.logstash.plugins.pipeline.PipelineInput
  java_import org.logstash.plugins.pipeline.ReceiveResponse

  config_name "pipeline"

  config :address, :validate => :string, :required => true

  attr_reader :pipeline_bus

  def register
    # May as well set this up here, writers won't do anything until
    # @running is set to false
    @running = java.util.concurrent.atomic.AtomicBoolean.new(false)
    @pipeline_bus = execution_context.agent.pipeline_bus
    listen_successful = pipeline_bus.listen(self, address)
    if !listen_successful
      raise ::LogStash::ConfigurationError, "Internal input at '#{@address}' already bound! Addresses must be globally unique across pipelines."
    end
    # add address to the plugin stats
    metric.gauge(:address, address)
  end

  def run(queue)
    @queue = queue
    # the wrapped write client supports batch pushes; plain queues (used in tests) may not
    @queue_supports_batch = queue.respond_to?(:push_batch)
    @running.set(true)

    while @running.get()
      sleep 0.1
    end
  end

  def running?
    @running && @running.get()
  end

  # Returns false if the receive failed due to a stopping input
  # To understand why this value is useful see Internal.send_to
  # Note, this takes a java Stream, not a ruby array
  def internalReceive(events)
    return ReceiveResponse.closing() if !@running.get()

    if @queue_supports_batch
      internal_receive_batch(events)
    else
      internal_receive_single(events)
    end
  end

  # pushes the whole batch through a single queue call, letting a persisted queue
  # write all events under one lock acquisition instead of one per event.
  # on failure the whole batch is reported as failed (position 0); events already
  # persisted will be duplicated when the upstream output retries, which is
  # consistent with the queue's at-least-once delivery semantics.
  def internal_receive_batch(events)
    batch = []
    events.forEach (lambda do |event|
      decorate(event)
      batch << event
    end)
    @queue.push_batch(batch)
    ReceiveResponse.completed()
  rescue java.lang.InterruptedException, org.logstash.ackedqueue.QueueRuntimeException, IOError => e
    logger.debug? && logger.debug('queueing batch failed', message: e.message, exception: e.class, backtrace: e.backtrace)
    ReceiveResponse.failed_at(0, e)
  end

  def internal_receive_single(events)
    stream_position = 0
    events.forEach (lambda do |event|
      decorate(event)
      @queue << event
      stream_position = stream_position + 1
    end)
    ReceiveResponse.completed()
  rescue java.lang.InterruptedException, org.logstash.ackedqueue.QueueRuntimeException, IOError => e
    logger.debug? && logger.debug('queueing event failed', message: e.message, exception: e.class, backtrace: e.backtrace)
    ReceiveResponse.failed_at(stream_position, e)
  end

  def stop
    pipeline_bus.unlisten(self, address)
    # We stop receiving events _after_ we unlisten to pick up any events sent by upstream outputs that
    # have not yet stopped
    @running.set(false) if @running # If register wasn't yet called, no @running!
  end

  def isRunning
    @running.get
  end
end; end; end; end; end
