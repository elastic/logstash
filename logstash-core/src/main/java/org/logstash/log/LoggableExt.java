package org.logstash.log;

import org.jruby.RubyClass;
import org.jruby.RubyModule;
import org.jruby.RubyString;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.Block;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.jruby.runtime.builtin.InstanceVariables;
import org.logstash.RubyUtil;

@JRubyModule(name = "Loggable")
public final class LoggableExt {

    private LoggableExt() {
        // Ruby Module
    }

    @JRubyMethod(module = true)
    public static RubyModule included(final ThreadContext context, final IRubyObject recv,
        final IRubyObject clazz) {
        final RubyModule klass = (RubyModule) clazz;
        klass.defineAnnotatedMethods(LoggableExt.ClassMethods.class);
        return klass;
    }

    @JRubyMethod
    public static IRubyObject logger(final ThreadContext context, final IRubyObject self) {
        return self.getSingletonClass().callMethod(context, "logger");
    }

    @JRubyMethod(name = "slow_logger", required = 4)
    public static IRubyObject slowLogger(final ThreadContext context, final IRubyObject self,
        final IRubyObject[] args) {
        return self.getSingletonClass().callMethod(context, "slow_logger", args);
    }

    private static RubyString log4jName(final ThreadContext context, final RubyModule self) {
        IRubyObject name = self.name19();
        if (name.isNil()) {
            final RubyClass clazz;
            if(self instanceof RubyClass) {
                clazz = ((RubyClass) self).getRealClass();
            } else {
                clazz = self.getMetaClass();
            }
            name = clazz.name19();
            if (name.isNil()) {
                name = clazz.to_s();
            }
        }
        return ((RubyString) ((RubyString) name).gsub(
            context, RubyUtil.RUBY.newString("::"), RubyUtil.RUBY.newString("."),
            Block.NULL_BLOCK
        )).downcase19(context);
    }

    /**
     * Holds the {@link JRubyMethod}s class methods that the {@link LoggableExt} module binds
     * on classes that include it (and hence invoke
     * {@link LoggableExt#included(ThreadContext, IRubyObject, IRubyObject)}).
     */
    public static final class ClassMethods {

        private ClassMethods() {
            // Holder for JRuby Methods
        }

        @JRubyMethod(meta = true)
        public static IRubyObject logger(final ThreadContext context, final IRubyObject self) {
            final InstanceVariables instanceVariables;
            if (self instanceof RubyClass) {
                instanceVariables = ((RubyClass) self).getRealClass().getInstanceVariables();
            } else {
                instanceVariables = self.getInstanceVariables();
            }
            IRubyObject logger = instanceVariables.getInstanceVariable("logger");
            if (logger == null || logger.isNil()) {
                logger = RubyUtil.LOGGER.callMethod(context, "new",
                    LoggableExt.log4jName(context, (RubyModule) self)
                );
                instanceVariables.setInstanceVariable("logger", logger);
            }
            return logger;
        }

        @JRubyMethod(name = "slow_logger", required = 4, meta = true)
        public static SlowLoggerExt slowLogger(final ThreadContext context,
            final IRubyObject self, final IRubyObject[] args) {
            final InstanceVariables instanceVariables = self.getInstanceVariables();
            SlowLoggerExt logger =
                (SlowLoggerExt) instanceVariables.getInstanceVariable("slow_logger");
            if (logger == null || logger.isNil()) {
                logger = new SlowLoggerExt(context.runtime, RubyUtil.SLOW_LOGGER).initialize(
                    context, new IRubyObject[]{
                        LoggableExt.log4jName(context, (RubyModule) self), args[0], args[1],
                        args[2], args[3]
                    }
                );
                instanceVariables.setInstanceVariable("slow_logger", logger);
            }
            return logger;
        }
    }
}
