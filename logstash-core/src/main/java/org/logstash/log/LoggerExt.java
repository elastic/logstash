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

import org.apache.logging.log4j.Level;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.apache.logging.log4j.core.LoggerContext;
import org.apache.logging.log4j.core.config.Configuration;
import org.apache.logging.log4j.core.config.LoggerConfig;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

import java.io.File;
import java.net.URI;

/**
 * JRuby extension, it's part of log4j wrapping for JRuby.
 * Wrapper log4j Logger as Ruby like class
 * */
@JRubyClass(name = "Logger")
public class LoggerExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    private static final Object CONFIG_LOCK = new Object();
    private Logger logger;

    public LoggerExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public LoggerExt initialize(final ThreadContext context, final IRubyObject loggerName) {
        logger = LogManager.getLogger(loggerName.asJavaString());
        return this;
    }

    @JRubyMethod(name = "trace?")
    public RubyBoolean isTrace(final ThreadContext context) {
        return logger.isTraceEnabled() ? context.tru : context.fals;
    }

    @JRubyMethod(name = "debug?")
    public RubyBoolean isDebug(final ThreadContext context) {
        return logger.isDebugEnabled() ? context.tru : context.fals;
    }

    @JRubyMethod(name = "info?")
    public RubyBoolean isInfo(final ThreadContext context) {
        return logger.isInfoEnabled() ? context.tru : context.fals;
    }

    @JRubyMethod(name = "error?")
    public RubyBoolean isError(final ThreadContext context) {
        return logger.isErrorEnabled() ? context.tru : context.fals;
    }

    @JRubyMethod(name = "warn?")
    public RubyBoolean isWarn(final ThreadContext context) {
        return logger.isWarnEnabled() ? context.tru : context.fals;
    }

    @JRubyMethod(name = "fatal?")
    public RubyBoolean isFatal(final ThreadContext context) {
        return logger.isDebugEnabled() ? context.tru : context.fals;
    }

    @JRubyMethod
    public IRubyObject trace(final IRubyObject msg) {
        if (logger.isTraceEnabled()) logger.trace(msg.asJavaString());
        return this;
    }

    @JRubyMethod
    public IRubyObject trace(final IRubyObject msg, final IRubyObject data) {
        if (logger.isTraceEnabled()) logger.trace(msg.asJavaString(), data);
        return this;
    }

    @JRubyMethod
    public IRubyObject debug(final IRubyObject msg) {
        if (logger.isDebugEnabled()) logger.debug(msg.asJavaString());
        return this;
    }

    @JRubyMethod
    public IRubyObject debug(final IRubyObject msg, final IRubyObject data) {
        if (logger.isDebugEnabled()) logger.debug(msg.asJavaString(), data);
        return this;
    }

    @JRubyMethod
    public IRubyObject info(final IRubyObject msg) {
        if (logger.isInfoEnabled()) logger.info(msg.asJavaString());
        return this;
    }

    @JRubyMethod
    public IRubyObject info(final IRubyObject msg, final IRubyObject data) {
        if (logger.isInfoEnabled()) logger.info(msg.asJavaString(), data);
        return this;
    }

    @JRubyMethod
    public IRubyObject warn(final IRubyObject msg) {
        logger.warn(msg.asJavaString());
        return this;
    }

    @JRubyMethod
    public IRubyObject warn(final IRubyObject msg, final IRubyObject data) {
        logger.warn(msg.asJavaString(), data);
        return this;
    }

    @JRubyMethod
    public IRubyObject error(final IRubyObject msg) {
        logger.error(msg.asJavaString());
        return this;
    }

    @JRubyMethod
    public IRubyObject error(final IRubyObject msg, final IRubyObject data) {
        logger.error(msg.asJavaString(), data);
        return this;
    }

    @JRubyMethod
    public IRubyObject fatal(final IRubyObject msg) {
        logger.fatal(msg.asJavaString());
        return this;
    }

    @JRubyMethod
    public IRubyObject fatal(final IRubyObject msg, final IRubyObject data) {
        logger.fatal(msg.asJavaString(), data);
        return this;
    }

    @JRubyMethod(name = "configure_logging", meta = true, required = 1, optional = 1)
    public static IRubyObject configureLogging(final ThreadContext context, final IRubyObject self,
                                        final IRubyObject args[]) {
        synchronized (CONFIG_LOCK) {
            IRubyObject path = args.length > 1 ? args[1] : null;
            String level = args[0].asJavaString();
            try {
                setLevel(level, (path == null || path.isNil()) ? null : path.asJavaString());
            } catch (Exception e) {
                throw new IllegalArgumentException(
                        String.format("invalid level[%s] for logger[%s]", level, path));
            }

        }
        return context.nil;
    }

    @JRubyMethod(name = {"reconfigure", "initialize"}, meta = true)
    public static IRubyObject reconfigure(final ThreadContext context, final IRubyObject self,
                                          final IRubyObject configPath) {
        synchronized (CONFIG_LOCK) {
            URI configLocation = URI.create(configPath.asJavaString());
            String filePath = configLocation.getPath();
            File configFile = new File(filePath);
            if (configFile.exists()) {
                String logsLocation = System.getProperty("ls.logs");
                System.out.println(String.format(
                        "Sending Logstash logs to %s which is now configured via log4j2.properties",
                        logsLocation));
                LoggerContext loggerContext = LoggerContext.getContext(false);
                loggerContext.setConfigLocation(configLocation);
                LogManager.setFactory(new LogstashLoggerContextFactory(loggerContext));
            } else {
                System.out.println(String.format(
                        "Could not find log4j2 configuration at path %s. Using default config " +
                                "which logs errors to the console",
                        filePath));
            }
        }
        return context.nil;
    }

    @JRubyMethod(name = "get_logging_context", meta = true)
    public static IRubyObject getLoggingContext(final ThreadContext context,
                                                final IRubyObject self) {
        return JavaUtil.convertJavaToUsableRubyObject(
                context.runtime, LoggerContext.getContext(false));
    }

    private static void setLevel(String level, String loggerPath) {
        LoggerContext loggerContext = LoggerContext.getContext(false);
        Configuration config = loggerContext.getConfiguration();
        Level logLevel = Level.valueOf(level);

        if (loggerPath == null || loggerPath.equals("")) {
            LoggerConfig rootLogger = config.getRootLogger();
            if (rootLogger.getLevel() != logLevel) {
                rootLogger.setLevel(logLevel);
                loggerContext.updateLoggers();
            }
        } else {
            LoggerConfig packageLogger = config.getLoggerConfig(loggerPath);
            if (!packageLogger.getName().equals(loggerPath)) {
                config.addLogger(loggerPath, new LoggerConfig(loggerPath, logLevel, true));
                loggerContext.updateLoggers();
            } else if (packageLogger.getLevel() != logLevel) {
                packageLogger.setLevel(logLevel);
                loggerContext.updateLoggers();
            }
        }
    }

}
