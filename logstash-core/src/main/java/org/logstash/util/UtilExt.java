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


package org.logstash.util;

import org.jruby.RubyThread;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * Utility methods class
 * */
@JRubyModule(name = "Util") // LogStash::Util
public class UtilExt {

    @JRubyMethod(module = true)
    public static IRubyObject get_thread_id(final ThreadContext context, IRubyObject self, IRubyObject thread) {
        if (!(thread instanceof RubyThread)) {
            throw context.runtime.newTypeError(thread, context.runtime.getThread());
        }
        final Thread javaThread = ((RubyThread) thread).getNativeThread(); // weak-reference
        System.out.println(javaThread);
        // even if thread is dead the RubyThread instance might stick around while the Java thread
        // instance already could have been garbage collected - let's return nil for dead meat :
        return javaThread == null ? context.nil : context.runtime.newFixnum(javaThread.getId());
    }

    @JRubyMethod(module = true)
    public static IRubyObject get_thread_name(final ThreadContext context, IRubyObject self, IRubyObject thread) {
        if (!(thread instanceof RubyThread)) {
            throw context.runtime.newTypeError(thread, context.runtime.getThread());
        }
        final Thread javaThread = ((RubyThread) thread).getNativeThread(); // weak-reference
        // even if thread is dead the RubyThread instance might stick around while the Java thread
        // instance already could have been garbage collected - let's return nil for dead meat :
        return javaThread == null ? context.nil : context.runtime.newString(javaThread.getName());
    }

    @JRubyMethod(module = true) // JRuby.reference(target).synchronized { ... }
    public static IRubyObject synchronize(final ThreadContext context, IRubyObject self, IRubyObject target, Block block) {
        synchronized (target) {
            return block.yieldSpecific(context);
        }
    }

}
