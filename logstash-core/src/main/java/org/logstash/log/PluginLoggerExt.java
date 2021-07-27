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

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.anno.JRubyModule;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;

/**
 * A specialized {@link LoggerExt} that injects logging context information.
 *
 * Ruby interface is exactly the same as with `LogStash::Logging::Logger`.
 *
 * @since 7.15
 */
@JRubyModule(name = "LogStash::Logging::PluginLogger")
public class PluginLoggerExt extends LoggerExt {

    private static final long serialVersionUID = 1L;

    static final String PLUGIN_ID_KEY = "plugin.id";

    private String pluginId;

    public PluginLoggerExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod
    public LoggerExt initialize(final ThreadContext context, final IRubyObject plugin) {
        initializeLogger(LoggableExt.log4jName(plugin.getMetaClass()));
        this.pluginId = plugin.callMethod(context, "id").asJavaString();
        return this;
    }

    @Override
    public IRubyObject trace(final IRubyObject msg) {
        if (logger.isTraceEnabled()) {
            org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

            logger.trace(msg.asString());

            org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);
        }
        return this;
    }

    @Override
    public IRubyObject trace(final IRubyObject msg, final IRubyObject data) {
        if (logger.isTraceEnabled()) {
            org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

            logger.trace(msg.toString(), data);

            org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);
        }
        return this;
    }

    @Override
    public IRubyObject debug(final IRubyObject msg) {
        if (logger.isDebugEnabled()) {
            org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

            logger.debug(msg.asString());

            org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);
        }
        return this;
    }

    @Override
    public IRubyObject debug(final IRubyObject msg, final IRubyObject data) {
        if (logger.isDebugEnabled()) {
            org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

            logger.debug(msg.toString(), data);

            org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);
        }
        return this;
    }

    @Override
    public IRubyObject info(final IRubyObject msg) {
        if (logger.isInfoEnabled()) {
            org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

            logger.info(msg.asString());

            org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);
        }
        return this;
    }

    @Override
    public IRubyObject info(final IRubyObject msg, final IRubyObject data) {
        if (logger.isInfoEnabled()) {
            org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

            logger.info(msg.toString(), data);

            org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);
        }
        return this;
    }

    @Override
    public IRubyObject warn(final IRubyObject msg) {
        org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

        logger.warn(msg.asString());

        org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);

        return this;
    }

    @Override
    public IRubyObject warn(final IRubyObject msg, final IRubyObject data) {
        org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

        logger.warn(msg.toString(), data);

        org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);

        return this;
    }

    @Override
    public IRubyObject error(final IRubyObject msg) {
        org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

        logger.error(msg.asString());

        org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);

        return this;
    }

    @Override
    public IRubyObject error(final IRubyObject msg, final IRubyObject data) {
        org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

        logger.error(msg.toString(), data);

        org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);

        return this;
    }

    @Override
    public IRubyObject fatal(final IRubyObject msg) {
        org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

        logger.fatal(msg.asString());

        org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);

        return this;
    }

    @Override
    public IRubyObject fatal(final IRubyObject msg, final IRubyObject data) {
        org.apache.logging.log4j.ThreadContext.put(PLUGIN_ID_KEY, pluginId);

        logger.fatal(msg.toString(), data);

        org.apache.logging.log4j.ThreadContext.remove(PLUGIN_ID_KEY);

        return this;
    }

}
