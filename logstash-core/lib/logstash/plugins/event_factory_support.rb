require 'logstash/util/thread_safe_attributes'

module LogStash
  module Plugins
    module EventFactorySupport

      include LogStash::Util::ThreadSafeAttributes


      lazy_init_attr :event_factory do
        create_event_factory
      end

      lazy_init_attr :targeted_event_factory do
        raise ArgumentError.new('config.target not present') unless respond_to?(:target)
        target.nil? ? event_factory : TargetedEventFactory(event_factory, target)
      end

      private

      # @private Internal API
      def create_event_factory
        BasicEventFactory::INSTANCE
      end

      class BasicEventFactory
        INSTANCE = new

        # @param payload [Hash]
        # @return [LogStash::Event]
        def new_event(payload)
          LogStash::Event.new(payload)
        end

      end
      private_constant :BasicEventFactory

      class TargetedEventFactory

        def initialize(inner, target)
          @delegate = inner
          @target = target
        end

        # @param payload [Hash]
        # @return [LogStash::Event]
        def new_event(payload)
          @delegate.new_event(@target => payload)
        end

      end
      private_constant :TargetedEventFactory

    end
  end
end
