# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/logging/logger"

module LogStash module Helpers
  ##
  # Holds an Elasticsearch client.
  # @see ElasticsearchClientHolder#create
  module ElasticsearchClientHolder

    ##
    # Creates an ElasticsearchClientHolder.
    # If a `tracker` is specified, an SslRebuildable instance
    # connected to the tracker with the provided id is returned;
    # Otherwise, a Lazy instance is returned.
    # @param tracker [#consume_stale, nil]
    # @param id [#to_sym, nil]
    # @yieldreturn [LogStash::Outputs::ElasticSearch::HttpClient]
    # @return [ElasticsearchClientHolder]
    def self.create(tracker=nil, id=nil, &client_factory)
      return Lazy.new(&client_factory) if tracker.nil?

      SslRebuildable.new(tracker, id, &client_factory)
    end

    ##
    # Get a current client for immediate use.
    # Consumers MUST NOT cache the returned client.
    # @return [LogStash::Outputs::ElasticSearch::HttpClient]
    def get
      fail NotImplementedError
    end

    ##
    # close the current client, if it exists and is connected
    # @return [void]
    def close
      fail NotImplementedError
    end

    ##
    # An ElasticsearchClientHolder that lazily creates the client when it is needed,
    # caching the result indefinitely.
    # @api internal (see ElasticsearchClientHolder::create)
    class Lazy
      include ElasticsearchClientHolder
      include LogStash::Util::Loggable

      ##
      # @yieldreturn [LogStash::Outputs::ElasticSearch::HttpClient]
      def initialize(&client_factory)
        fail ArgumentError, "client_factory block is required" unless block_given?
        @client_factory = client_factory
      end

      def get
        @client || Util.synchronize(self) do
          @client ||= begin
                        logger.debug("initializing ES client")
                        @client_factory.call
                      end
        end
      end

      def close
        Util.synchronize(self) do
          @client&.close
        end
      end
    end

    ##
    # An ElasticsearchClientHolder that is connected to the provided tracker by the provided id.
    # The client is created lazily, and is re-created when the tracker has marked the given id as stale.
    # @api internal (see ElasticsearchClientHolder::create)
    class SslRebuildable
      include ElasticsearchClientHolder
      include LogStash::Util::Loggable

      attr_reader :tracker
      attr_reader :id

      ##
      # @param tracker [#consume_stale]
      # @param id [#to_sym]
      # @yieldreturn [LogStash::Outputs::ElasticSearch::HttpClient]
      def initialize(tracker, id, &client_factory)
        @tracker = tracker or fail(ArgumentError, "tracker is required")
        @id = id&.to_sym or fail(ArgumentError, "id is required")
        @client_factory = client_factory or fail(ArgumentError, "client_factory block is required")
      end

      def get
        Util.synchronize(self) do
          @client ||= begin
                        logger.debug("initializing rebuildable elasticsearch client `#{@id}`")
                        @client_factory.call
                      end

          @tracker.consume_stale(@id) do
            begin
              old_client = @client
              @client = @client_factory.call
              logger.debug("rebuilt elasticsearch client `#{@id}` on certificate change")
              old_client&.close rescue logger.warn("error closing stale elasticsearch client `#{@id}`", exception: $!.class, message: $!.message)
            rescue => e
              logger.warn("failed to rebuild elasticsearch client `#{@id}`", exception: e.class, message: e.message)
              raise
            end
          end

          @client
        end
      end

      def close
        Util.synchronize(self) do
          @client&.close
        end
      end
    end
  end
end end
