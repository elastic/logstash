# encoding: utf-8
module LogStash
  class EventDispatcher
    java_import "java.util.concurrent.CopyOnWriteArraySet"

    attr_reader :emitter

    def initialize(emitter)
      @emitter = emitter
      @listeners = CopyOnWriteArraySet.new
    end

    # This operation is slow because we use a CopyOnWriteArrayList
    # But the majority of the addition will be done at bootstrap time
    # So add_listener shouldn't be called often at runtime.
    #
    # On the other hand the notification could be called really often.
    def add_listener(listener)
      @listeners.add(listener)
    end

    # This operation is slow because we use a `CopyOnWriteArrayList` as the backend, instead of a
    # ConcurrentHashMap, but since we are mostly adding stuff and iterating the `CopyOnWriteArrayList`
    # should provide a better performance.
    #
    # See note on add_listener, this method shouldn't be called really often.
    def remove_listener(listener)
      @listeners.remove(listener)
    end

    def fire(method_name, *arguments)
      @listeners.each do |listener|
        if listener.respond_to?(method_name)
          listener.send(method_name, emitter, *arguments)
        end
      end
    end
    alias_method :execute, :fire
  end
end
