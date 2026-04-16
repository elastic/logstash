# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/logging/logger"

module LogStash module Helpers
  # Owns a lazily-built ES client and, when a tracker+id are provided,
  # rebuilds it on certificate rotation.
  #
  # Without a tracker (e.g. ssl.reload.automatic=false), behaves as a plain
  # lazy client cache with no rebuild logic.
  class SslRebuildable
    include LogStash::Util::Loggable

    # @param tracker [LogStash::SslFileTracker, nil] may be nil when SSL auto-reload is disabled
    # @param id [Symbol, String, nil] tracking id; ignored when tracker is nil
    # @yield factory that builds a fresh client instance
    def initialize(tracker, id, &client_factory)
      raise ArgumentError, "client_factory block is required" unless block_given?
      @tracker = tracker
      @id = id&.to_sym
      @client_factory = client_factory
    end

    # Lazily builds and returns the current client. Subsequent calls return
    # the same instance until #invalidate or a #maybe_rebuild consumes stale.
    def client
      @client ||= @client_factory.call
    end

    # Asks the tracker whether the bound id is stale; if so, closes the current
    # client and eagerly rebuilds a fresh one so the next #client call returns
    # the new instance immediately. If the rebuild raises, the tracker
    # re-asserts the stale flag so the next call retries.
    # @return [Boolean] true if the rebuild path ran
    def maybe_rebuild
      return false unless @tracker
      @tracker.consume_stale(@id) do
        invalidate
        client
        logger.info("Rebuilt client on certificate change")
      end
    end

    private

    # Closes and clears the current client. Any close error is logged and swallowed.
    def invalidate
      @client&.close
    rescue => e
      logger.warn("Error closing stale ES client", :message => e.message)
    ensure
      @client = nil
    end
  end
end end
