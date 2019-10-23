package org.logstash.log;

import co.elastic.logstash.api.DeprecationLogger;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

@JRubyClass(name = "DeprecationLogger")
public class DeprecationLoggerExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private DeprecationLogger logger;

    public DeprecationLoggerExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public DeprecationLoggerExt initialize(final ThreadContext context, final IRubyObject loggerName) {
        logger = new DefaultDeprecationLogger(loggerName.asJavaString());
        return this;
    }

    @JRubyMethod(name = "deprecated", required = 1, optional = 1)
    public IRubyObject rubyDeprecated(final ThreadContext context, final IRubyObject[] args) {
        if (args.length > 1) {
            logger.deprecated(args[0].asJavaString(), args[1]);
        } else {
            logger.deprecated(args[0].asJavaString());
        }
        return this;
    }
}
