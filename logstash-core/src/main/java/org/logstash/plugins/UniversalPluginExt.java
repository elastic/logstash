package org.logstash.plugins;

import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "UniversalPlugin")
public final class UniversalPluginExt extends RubyBasicObject {

    public UniversalPluginExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public IRubyObject initialize(final ThreadContext context) {
        return this;
    }

    @JRubyMethod(name = "register_hooks")
    public IRubyObject registerHooks(final ThreadContext context, final IRubyObject hookManager) {
        return context.nil;
    }

    @JRubyMethod(name = "additionals_settings")
    public IRubyObject additionalSettings(final ThreadContext context, final IRubyObject settings) {
        return context.nil;
    }
}
