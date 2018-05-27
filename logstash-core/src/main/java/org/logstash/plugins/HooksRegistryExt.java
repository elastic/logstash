package org.logstash.plugins;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyFixnum;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import java.util.List;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.CopyOnWriteArrayList;

@JRubyClass(name = "HooksRegistry")
public final class HooksRegistryExt extends RubyObject {
    private ConcurrentHashMap<IRubyObject, IRubyObject> registeredEmitters;
    private ConcurrentHashMap<IRubyObject, List<IRubyObject>> registeredHooks;

    public HooksRegistryExt(Ruby runtime, RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public IRubyObject initialize(final ThreadContext context) {
        registeredEmitters = new ConcurrentHashMap<>();
        registeredHooks = new ConcurrentHashMap<>();
        return this;
    }

    @JRubyMethod(name = "register_emitter")
    public IRubyObject registerEmitter(final ThreadContext context, final IRubyObject emitterScope, final IRubyObject dispatcher) {
        registeredEmitters.put(emitterScope, dispatcher);
        return syncHooks(context);
    }

    @JRubyMethod(name = "remove_emitter")
    public IRubyObject removeEmitter(final ThreadContext context, final IRubyObject emitterScope) {
        return registeredEmitters.remove(emitterScope);
    }

    @JRubyMethod(name = "register_hooks")
    public IRubyObject registerHooks(final ThreadContext context, final IRubyObject emitterScope, final IRubyObject callback) {
        final List<IRubyObject> callbacks =
                registeredHooks.computeIfAbsent(emitterScope, iRubyObject -> new CopyOnWriteArrayList<>());
        callbacks.add(callback);
        return syncHooks(context);
    }

    @JRubyMethod(name = "emitters_count")
    public IRubyObject emittersCount(final ThreadContext context) {
        return RubyFixnum.newFixnum(context.runtime, registeredEmitters.size());
    }

    @JRubyMethod(name = "hooks_count", optional = 1)
    public IRubyObject hooksCount(final ThreadContext context, final IRubyObject[] args) {
        final IRubyObject emitterScope = args.length > 0 ? args[0] : context.nil;
        final int hooksCount;
        if (emitterScope.isNil()) {
            hooksCount = registeredHooks.values().stream().mapToInt(List::size).sum();
        } else {
            final List<IRubyObject> callbacks = registeredHooks.get(emitterScope);
            if (callbacks == null) {
                hooksCount = 0;
            } else {
                hooksCount = registeredHooks.get(emitterScope).size();
            }
        }
        return RubyFixnum.newFixnum(context.runtime, hooksCount);
    }

    @JRubyMethod(name = "registered_hook?")
    public IRubyObject ifRegisteredHook(final ThreadContext context, final IRubyObject emitterScope, final IRubyObject klass) {
        final List<IRubyObject> callbacks = registeredHooks.get(emitterScope);
        if (callbacks == null) {
            return context.fals;
        }
        return callbacks.stream().map(IRubyObject::getMetaClass).anyMatch(clazz -> clazz.eql(klass))
                ? context.tru : context.fals;
    }

    private IRubyObject syncHooks(final ThreadContext context) {
        registeredEmitters.forEach((emitter, dispatcher) -> {
            final List<IRubyObject> listeners = registeredHooks.get(emitter);
            if (listeners != null) {
                for (final IRubyObject listener : listeners) {
                    dispatcher.callMethod(context, "add_listener", listener);
                }
            }
        });
        return context.nil;
    }
}
