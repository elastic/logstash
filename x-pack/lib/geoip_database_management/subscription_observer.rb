# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require "thread"

require 'observer'
require 'concurrent/atomic/reentrant_read_write_lock'

module LogStash module GeoipDatabaseManagement
  ##
  # Provide a SubscriptionObserver or a SubscriptionObserver::coerce-able object
  # to Subscription#observe to use the current value and observe changes to the
  # subscription's state
  #
  # @api public
  module SubscriptionObserver

    ##
    # Coerce an object into an SubscriptionObserver, if necessary
    # @overload coerce(observer)
    #   @param observer [SubscriptionObserver]
    #   @return [SubscriptionObserver]
    # @overload coerce(construct:, :on_update, :on_expire)
    #   @param construct [Proc(DbInfo)->void]: a single-arity Proc that will receive the current
    #                                          DbInfo at the beginning of observation
    #   @param on_update [Proc(DbInfo)->void]: a single-arity Proc that will receive notifications
    #                                          of each subsequent `DBInfo`
    #   @param on_expire [Proc()->void]: a zero-arity Proc that will receive notifications of the
    #                                    current value expiring.
    #   @return [SubscriptionObserver::Proxy]
    # @api public
    def self.coerce(observer_spec)
      return observer_spec if Observer === observer_spec
      return Proxy.new(**observer_spec) if observer_spec.kind_of?(Hash)

      fail ArgumentError, "Could not make a SubscriptionObserver from #{observer_spec.inspect}"
    end

    ##
    # Observe the value at observer's construction, before any state-change notifications are fired
    def construct(initial_value)
      fail NotImplementedError
    end

    ##
    # Observe an update notice, after construction is complete
    def on_update(updated_value)
      fail NotImplementedError
    end

    ##
    # Observe an expiry notice, after construction is complete
    def on_expire
      fail NotImplementedError
    end

    ##
    # @api internal
    # @see SubscriptionObserver#coerce
    class Proxy
      include SubscriptionObserver

      def initialize(construct:, on_update:, on_expire:)
        fail ArgumentError unless construct.lambda? && construct.arity == 1
        fail ArgumentError unless on_update.lambda? && on_update.arity == 1
        fail ArgumentError unless on_expire.lambda? && on_expire.arity == 0

        @construct = construct
        @on_update = on_update
        @on_expire = on_expire
      end

      def construct(initial_value)
        @construct.call(initial_value)
      end

      def on_update(updated_value)
        @on_update.call(updated_value)
      end

      def on_expire
        @on_expire.call
      end
    end
    private_constant :Proxy
  end
end end