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

import static org.logstash.RubyUtil.RUBY;

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

    @JRubyMethod(name= "deprecation_logger")
    public static IRubyObject deprecationLogger(final ThreadContext context, final IRubyObject self) {
        return self.getSingletonClass().callMethod(context, "deprecation_logger");
    }

    private static RubyString log4jName(final ThreadContext context, final RubyModule self) {
        IRubyObject name = self.name(context);
        if (name.isNil()) {
            final RubyClass clazz;
            if (self instanceof RubyClass) {
                clazz = ((RubyClass) self).getRealClass();
            } else {
                clazz = self.getMetaClass();
            }
            name = clazz.name(context);
            if (name.isNil()) {
                name = clazz.to_s();
            }
        }
        return ((RubyString) ((RubyString) name).gsub(
            context, RUBY.newString("::"), RUBY.newString("."),
            Block.NULL_BLOCK
        )).downcase(context);
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

        @JRubyMethod(name = "deprecation_logger", meta = true)
        public static IRubyObject deprecationLogger(final ThreadContext context, final IRubyObject self) {
            final InstanceVariables instanceVariables;
            if (self instanceof RubyClass) {
                instanceVariables = ((RubyClass) self).getRealClass().getInstanceVariables();
            } else {
                instanceVariables = self.getInstanceVariables();
            }
            IRubyObject logger = instanceVariables.getInstanceVariable("deprecation_logger");
            if (logger == null || logger.isNil()) {
                logger = new DeprecationLoggerExt(context.runtime, RubyUtil.DEPRECATION_LOGGER)
                        .initialize(context, LoggableExt.log4jName(context, (RubyModule) self));
                instanceVariables.setInstanceVariable("deprecation_logger", logger);
            }
            return logger;
        }
    }
}
