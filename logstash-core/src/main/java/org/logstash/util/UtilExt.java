package org.logstash.util;

import org.jruby.RubyThread;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyModule(name = "Util") // LogStash::Util
public class UtilExt {

    @JRubyMethod(module = true)
    public static IRubyObject get_thread_id(final ThreadContext context, IRubyObject self, IRubyObject thread) {
        if (!(thread instanceof RubyThread)) {
            throw context.runtime.newTypeError(thread, context.runtime.getThread());
        }
        final Thread javaThread = ((RubyThread) thread).getNativeThread(); // weak-reference
        // even if thread is dead the RubyThread instance might stick around while the Java thread
        // instance already could have been garbage collected - let's return nil for dead meat :
        return javaThread == null ? context.nil : context.runtime.newFixnum(javaThread.getId());
    }

}
