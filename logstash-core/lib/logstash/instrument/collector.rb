# encoding: utf-8
require "logstash/instrument/snapshot"
require "logstash/instrument/metric_store"
require "logstash/util/loggable"
require "concurrent/timer_task"
require "observer"
require "singleton"
require "thread"

module LogStash module Instrument
  # The Collector is the single point of reference for all
  # the metrics collection inside logstash, the metrics library will make
  # direct calls to this class.
  #
  # This class is an observable responsable of periodically emitting view of the system
  # to other components like the internal metrics pipelines.
  class Collector
    include LogStash::Util::Loggable
    include Observable

    SNAPSHOT_ROTATION_TIME_SECS = 1 # seconds
    SNAPSHOT_ROTATION_TIMEOUT_INTERVAL_SECS = 10 * 60 # seconds

    attr_accessor :agent

    def initialize
      @metric_store = MetricStore.new
      @agent = nil
      start_periodic_snapshotting
    end

    # The metric library will call this unique interface
    # its the job of the collector to update the store with new metric
    # of update the metric
    #
    # If there is a problem with the key or the type of metric we will record an error
    # but we wont stop processing events, theses errors are not considered fatal.
    #
    def push(namespaces_path, key, type, *metric_type_params)
      begin
        metric = @metric_store.fetch_or_store(namespaces_path, key) do
          LogStash::Instrument::MetricType.create(type, namespaces_path, key)
        end

        metric.execute(*metric_type_params)

        changed # we had changes coming in so we can notify the observers
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

    # Monitor the `Concurrent::TimerTask` this update is triggered on every successful or not
    # run of the task, TimerTask implement Observable and the collector acts as
    # the observer and will keep track if something went wrong in the execution.
    #
    # @param [Time] Time of execution
    # @param [result] Result of the execution
    # @param [Exception] Exception
    def update(time_of_execution, result, exception)
      return true if exception.nil?
      logger.error("Collector: Something went wrong went sending data to the observers",
                   :execution_time => time_of_execution,
                   :result => result,
                   :exception => exception.class.name)
    end

    # Snapshot the current Metric Store and return it immediately,
    # This is useful if you want to get access to the current metric store without
    # waiting for a periodic call.
    #
    # @return [LogStash::Instrument::MetricStore]
    def snapshot_metric
      Snapshot.new(@metric_store)
    end

    # Configure and start the periodic task for snapshotting the `MetricStore`
    def start_periodic_snapshotting
      @snapshot_task = Concurrent::TimerTask.new { publish_snapshot }
      @snapshot_task.execution_interval = SNAPSHOT_ROTATION_TIME_SECS
      @snapshot_task.timeout_interval = SNAPSHOT_ROTATION_TIMEOUT_INTERVAL_SECS
      @snapshot_task.add_observer(self)
      @snapshot_task.execute
    end

    def stop
      @snapshot_task.shutdown
    end

    # Create a snapshot of the MetricStore and send it to to the registered observers
    # The observer will receive the following signature in the update methode.
    #
    # `#update(created_at, metric_store)`
    def publish_snapshot
      created_at = Time.now
      logger.debug("Collector: Sending snapshot to observers", :created_at => created_at) if logger.debug?
      notify_observers(snapshot_metric)
    end

    def clear(keypath)
      @metric_store.prune(keypath)
    end
  end
end; end
