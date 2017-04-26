# encoding: utf-8
require "logstash/errors"

module LogStash
  # This class allow us to keep track and uniform all the return values from the
  # action task
  class ConvergeResult
    class ActionResult
      attr_reader :executed_at

      def initialize
        @executed_at = LogStash::Timestamp.now
      end

      # Until all the action have more granularity in the validation
      # or execution we make the ConvergeResult works with primitives and exceptions
      def self.create(action, action_result)
        if action_result.is_a?(ActionResult)
          action_result
        elsif action_result.is_a?(Exception)
          FailedAction.from_exception(action_result)
        elsif action_result == true
          SuccessfulAction.new
        elsif action_result == false
          FailedAction.from_action(action, action_result)
        else
          raise LogStash::Error, "Don't know how to handle `#{action_result.class}` for `#{action}`"
        end
      end
    end

    class FailedAction < ActionResult
      attr_reader :message, :backtrace

      def initialize(message, backtrace = nil)
        super()

        @message = message
        @backtrace = backtrace
      end

      def self.from_exception(exception)
        FailedAction.new(exception.message, exception.backtrace)
      end

      def self.from_action(action, action_result)
        FailedAction.new("Could not execute action: #{action}, action_result: #{action_result}")
      end

      def successful?
        false
      end
    end

    class SuccessfulAction < ActionResult
      def successful?
        true
      end
    end

    def initialize(expected_actions_count)
      @expected_actions_count = expected_actions_count
      @actions = {}
    end

    def add(action, action_result)
      @actions[action] = ActionResult.create(action, action_result)
    end

    def failed_actions
      filter_by_successful_state(false)
    end

    def successful_actions
      filter_by_successful_state(true)
    end

    def complete?
      total == @expected_actions_count
    end

    def success?
      failed_actions.empty? && complete?
    end

    def fails_count
      failed_actions.size
    end

    def success_count
      successful_actions.size
    end

    def total
      @actions.size
    end

    private
    def filter_by_successful_state(predicate)
      @actions.select { |action, action_result| action_result.successful? == predicate }
    end
  end
end
