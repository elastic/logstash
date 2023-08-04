# Copyright Elasticsearch B.V. and/or licensed to Elasticsearch B.V. under one
# or more contributor license agreements. Licensed under the Elastic License;
# you may not use this file except in compliance with the Elastic License.

require "logstash/util/loggable"
require "thread"

require 'observer'
require 'concurrent/atomic/reentrant_read_write_lock'

module LogStash module GeoipDatabaseManagement
  ##
  # A Subscription is acquired with Manager#subscribe_database_path
  class Subscription
    include LogStash::Util::Loggable
    include Observable # @api internal

    ##
    # @param initial [DBInfo]
    # @param state [#release!]
    # @api private
    def initialize(initial, state=nil)
      @state = state
      @observable = true
      @value = initial
      @lock = Concurrent::ReentrantReadWriteLock.new
    end

    ##
    # @overload value(&consumer)
    #   Yields the current DbInfo and prevents changes from occurring until control is returned.
    #   @note: this is intended for short-lived locks ONLY, as blocking writes will prevent updates
    #          from being observed by other subscribers.
    #   @yield db_info yields current DBInfo and returns the result of the block
    #   @yieldparam db_info [DbInfo]
    #   @return [Object] the result of the provided block
    # @overload value()
    #   Returns the current DBInfo immediately
    #   @return [DbInfo]
    def value(&consumer)
      @lock.with_read_lock do
        return yield(@value) if block_given?

        @value
      end
    end

    ##
    # Register an observer that will observe the current value and each subsequent update and expire,
    # until Subscription#release!
    #
    # @note: interacting with this Subscription or the Manager in any way in the provided hooks is
    # not advised, as it may cause deadlocks.
    #
    # @param construct [Proc(DbInfo)->void]: a single-arity Proc that will receive the current
    #                                        DbInfo at the beginning of observation
    # @param on_update [Proc(DbInfo)->void]: a single-arity Proc that will receive notifications
    #                                        of each subsequent `DBInfo`
    # @param on_expire [Proc()->void]: a zero-arity Proc that will receive notifications of the
    #                                  current value expiring.
    # @return [Subscription]
    def observe(construct:, on_update:, on_expire:)
      fail ArgumentError unless construct.lambda? && construct.arity == 1
      fail ArgumentError unless on_update.lambda? && on_update.arity == 1
      fail ArgumentError unless on_expire.lambda? && on_expire.arity == 0

      @lock.with_write_lock do
        fail "Subscription has been released!" unless @observable

        construct.call(@value)
        self.add_observer do |new_value|
          @lock.with_read_lock do
            if new_value.expired?
              on_expire.call
            else
              on_update.call(new_value)
            end
          end
        end
      end

      self
    end

    ##
    # Releases this subscription and all of its observers
    # from receiving additional notifications.
    def release!
      @lock.with_write_lock do
        @observable = false
        delete_observers

        @state&.release!(self)
        @state = nil
      end
    end

    ##
    # @api internal
    def notify(updated_value)
      write_lock_held = @lock.acquire_write_lock
      @value = updated_value

      # downgrade to read lock for notifications
      @lock.with_read_lock do
        write_lock_held = !@lock.release_write_lock
        self.changed
        self.notify_observers(updated_value)
      end
    ensure
      @lock.release_read_lock if write_lock_held
    end

    ##
    # @api private
    def add_observer(*args, &block)
      @lock.with_write_lock do
        if block_given?
          super(block, :call)
        else
          super(*args)
        end
      end
    end
  end
end end
