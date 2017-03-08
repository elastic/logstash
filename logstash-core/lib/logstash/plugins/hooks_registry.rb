# encoding: utf-8
module LogStash module Plugins
  # This calls allow logstash to expose the endpoints for listeners
  class HooksRegistry
    java_import "java.util.concurrent.ConcurrentHashMap"
    java_import "java.util.concurrent.CopyOnWriteArrayList"

    def initialize
      @registered_emitters = ConcurrentHashMap.new
      @registered_hooks = ConcurrentHashMap.new
    end

    def register_emitter(emitter_scope, dispatcher)
      @registered_emitters.put(emitter_scope, dispatcher)
      sync_hooks
    end

    def remove_emitter(emitter_scope)
      @registered_emitters.remove(emitter_scope)
    end

    def register_hooks(emitter_scope, callback)
      callbacks = @registered_hooks.computeIfAbsent(emitter_scope) do
        CopyOnWriteArrayList.new
      end

      callbacks.add(callback)
      sync_hooks
    end

    def emitters_count
      @registered_emitters.size
    end

    def hooks_count(emitter_scope = nil)
      if emitter_scope.nil?
        @registered_hooks.elements().collect(&:size).reduce(0, :+)
      else
        callbacks = @registered_hooks.get(emitter_scope)
        callbacks.nil? ? 0 : @registered_hooks.get(emitter_scope).size
      end
    end

    private
    def sync_hooks
      @registered_emitters.each do |emitter, dispatcher|
        listeners = @registered_hooks.get(emitter)

        unless listeners.nil?
          listeners.each do |listener|
            dispatcher.add_listener(listener)
          end
        end
      end
    end
  end
end end
