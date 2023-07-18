require 'logstash/util/thread_safe_attributes'

module LogStash
  module Plugins
    module EventFactorySupport
      extend LogStash::Util::ThreadSafeAttributes

      # The event_factory method is effectively final and should not be re-defined by plugins.
      #
      # @return an event factory object with a `new_event(Hash)` API
      # @since LS 7.14
      lazy_init_attr(:event_factory, variable: :@_event_factory) { create_event_factory }

      # The `targeted_event_factory` method is effectively final and should not be re-defined.
      # If the plugin defines a `target => ...` option than this method will return a factory
      # that respects the set target, otherwise (no target) returns {#event_factory}.
      #
      # @return an event factory object with a `new_event(Hash)` API
      # @since LS 7.14
      lazy_init_attr :targeted_event_factory, variable: :@_targeted_event_factory do
        raise ArgumentError.new('config(:target) not present') unless respond_to?(:target)
        target.nil? ? event_factory : TargetedEventFactory.new(event_factory, target)
      end

      private

      # @api private
      # @since LS 7.14
      def create_event_factory
        BasicEventFactory::INSTANCE
      end

      class BasicEventFactory
        INSTANCE = new

        # @param payload [Hash]
        # @return [LogStash::Event]
        def new_event(payload = {})
          LogStash::Event.new(payload)
        end

      end
      private_constant :BasicEventFactory

      class TargetedEventFactory

        def initialize(inner, target)
          fail(ArgumentError, "invalid EventFactory `#{inner}`") unless inner.respond_to?(:new_event)
          fail(ArgumentError, "invalid target field reference `#{target}`") unless org.logstash.FieldReference.isValid(target)
          @delegate = inner
          @target = target
        end

        # @param payload [Hash]
        # @return [LogStash::Event]
        def new_event(payload = {})
          event = @delegate.new_event
          event.set(@target, payload)
          event
        end

      end
      private_constant :TargetedEventFactory
    end
  end
end
