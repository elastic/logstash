module LogStash
  module Plugins
    module EventFactorySupport

      def event_factory
        @event_factory ||= default_event_factory
      end
      attr_writer :event_factory

      def default_event_factory
        DefaultEventFactory::INSTANCE
      end

      def event_factory_builder
        Builder.new self, default_event_factory
      end

      class Builder

        def initialize(plugin, factory)
          @plugin = plugin
          @factory = factory
        end

        # @return an event factory
        def build
          @plugin.event_factory = @factory
        end

        # @return [Builder] self
        def with_target(target)
          unless target.nil?
            @factory = TargetedEventFactory.new(@factory, target)
          end
          self
        end

      end

      class DefaultEventFactory
        INSTANCE = new

        # @param payload [Hash]
        # @return [LogStash::Event]
        def new_event(payload)
          LogStash::Event.new(payload)
        end

      end
      private_constant :DefaultEventFactory

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
