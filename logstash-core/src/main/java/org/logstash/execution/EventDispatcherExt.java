package org.logstash.execution;

import java.util.Collection;
import java.util.concurrent.CopyOnWriteArraySet;
import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "EventDispatcher")
public final class EventDispatcherExt extends RubyBasicObject {

    private final Collection<IRubyObject> listeners = new CopyOnWriteArraySet<>();

    private IRubyObject emitter;

    public EventDispatcherExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public EventDispatcherExt initialize(final ThreadContext context, final IRubyObject emitter) {
        this.emitter = emitter;
        return this;
    }

    @JRubyMethod
    public IRubyObject emitter() {
        return emitter;
    }

    /**
     * This operation is slow because we use a CopyOnWriteArrayList
     * But the majority of the addition will be done at bootstrap time
     * So add_listener shouldn't be called often at runtime.
     * On the other hand the notification could be called really often.
     * @param context ThreadContext
     * @param listener Listener
     * @return Nil
     */
    @JRubyMethod(name = "add_listener")
    public IRubyObject addListener(final ThreadContext context, final IRubyObject listener) {
        return listeners.add(listener) ? context.tru : context.fals;
    }

    /**
     * This operation is slow because we use a `CopyOnWriteArrayList` as the backend, instead of a
     * ConcurrentHashMap, but since we are mostly adding stuff and iterating the `CopyOnWriteArrayList`
     * should provide a better performance.
     * See note on add_listener, this method shouldn't be called really often.
     * @param context ThreadContext
     * @param listener Listener
     * @return True iff listener was actually removed
     */
    @JRubyMethod(name = "remove_listener")
    public IRubyObject removeListener(final ThreadContext context, final IRubyObject listener) {
        return listeners.remove(listener) ? context.tru : context.fals;
    }

    @JRubyMethod(name = {"execute", "fire"}, required = 1, rest = true)
    public IRubyObject fire(final ThreadContext context, final IRubyObject[] arguments) {
        final String methodName = arguments[0].asJavaString();
        final IRubyObject[] args = new IRubyObject[arguments.length];
        args[0] = emitter;
        System.arraycopy(arguments, 1, args, 1, arguments.length - 1);
        listeners.forEach(listener -> {
            if (listener.respondsTo(methodName)) {
                listener.callMethod(context, methodName, args);
            }
        });
        return context.nil;
    }
}
