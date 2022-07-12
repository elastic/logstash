/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


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

/**
 * JRuby extension that provides a class to keep track of listener and dispatch events to those.
 * */
@JRubyClass(name = "EventDispatcher")
public final class EventDispatcherExt extends RubyBasicObject {

    private static final long serialVersionUID = 1L;

    private final transient Collection<IRubyObject> listeners = new CopyOnWriteArraySet<>();

    private transient IRubyObject emitter;

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
