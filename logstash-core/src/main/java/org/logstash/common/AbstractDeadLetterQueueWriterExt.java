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


package org.logstash.common;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubyObject;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.common.io.DeadLetterQueueWriter;
import org.logstash.ext.JrubyEventExtLibrary;

@JRubyClass(name = "AbstractDeadLetterQueueWriter")
public abstract class AbstractDeadLetterQueueWriterExt extends RubyObject {

    private static final long serialVersionUID = 1L;

    AbstractDeadLetterQueueWriterExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = "is_open")
    public final RubyBoolean isOpen(final ThreadContext context) {
        return open(context);
    }

    @JRubyMethod(name = "plugin_id")
    public final IRubyObject pluginId(final ThreadContext context) {
        return getPluginId(context);
    }

    @JRubyMethod(name = "plugin_type")
    public final IRubyObject pluginType(final ThreadContext context) {
        return getPluginType(context);
    }

    @JRubyMethod(name = "inner_writer")
    public final IRubyObject innerWriter(final ThreadContext context) {
        return getInnerWriter(context);
    }

    @JRubyMethod
    public final IRubyObject write(final ThreadContext context, final IRubyObject event,
        final IRubyObject reason) {
        return doWrite(context, event, reason);
    }

    @JRubyMethod
    public final IRubyObject close(final ThreadContext context) {
        return doClose(context);
    }

    protected abstract RubyBoolean open(ThreadContext context);

    protected abstract IRubyObject getPluginId(ThreadContext context);

    protected abstract IRubyObject getPluginType(ThreadContext context);

    protected abstract IRubyObject getInnerWriter(ThreadContext context);

    protected abstract IRubyObject doWrite(ThreadContext context, IRubyObject event,
        IRubyObject reason);

    protected abstract IRubyObject doClose(ThreadContext context);

    @JRubyClass(name = "DummyDeadLetterQueueWriter")
    public static final class DummyDeadLetterQueueWriterExt
        extends AbstractDeadLetterQueueWriterExt {

        private static final long serialVersionUID = 1L;

        public DummyDeadLetterQueueWriterExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @Override
        @JRubyMethod
        public IRubyObject initialize(final ThreadContext context) {
            return super.initialize(context);
        }

        @Override
        protected IRubyObject getPluginId(final ThreadContext context) {
            return context.nil;
        }

        @Override
        protected IRubyObject getPluginType(final ThreadContext context) {
            return context.nil;
        }

        @Override
        protected IRubyObject getInnerWriter(final ThreadContext context) {
            return context.nil;
        }

        @Override
        protected IRubyObject doWrite(final ThreadContext context, final IRubyObject event,
            final IRubyObject reason) {
            return context.nil;
        }

        @Override
        protected IRubyObject doClose(final ThreadContext context) {
            return context.nil;
        }

        @Override
        protected RubyBoolean open(final ThreadContext context) {
            return context.fals;
        }
    }

    @JRubyClass(name = "PluginDeadLetterQueueWriter")
    public static final class PluginDeadLetterQueueWriterExt
        extends AbstractDeadLetterQueueWriterExt {

        private static final long serialVersionUID = 1L;

        private transient IRubyObject writerWrapper;

        private transient DeadLetterQueueWriter innerWriter;

        private transient IRubyObject pluginId;

        private transient IRubyObject pluginType;

        private String pluginIdString;

        private String pluginTypeString;

        public PluginDeadLetterQueueWriterExt(final Ruby runtime, final RubyClass metaClass) {
            super(runtime, metaClass);
        }

        @JRubyMethod
        public AbstractDeadLetterQueueWriterExt.PluginDeadLetterQueueWriterExt initialize(
            final ThreadContext context, final IRubyObject innerWriter, final IRubyObject pluginId,
            final IRubyObject pluginType) {
            writerWrapper = innerWriter;
            if (writerWrapper.getJavaClass().equals(DeadLetterQueueWriter.class)) {
                this.innerWriter = writerWrapper.toJava(
                    DeadLetterQueueWriter.class
                );
            }
            this.pluginId = pluginId;
            if (!pluginId.isNil()) {
                pluginIdString = pluginId.asJavaString();
            }
            this.pluginType = pluginType;
            if (!pluginType.isNil()) {
                pluginTypeString = pluginType.asJavaString();
            }
            return this;
        }

        @Override
        protected IRubyObject getPluginId(final ThreadContext context) {
            return pluginId;
        }

        @Override
        protected IRubyObject getPluginType(final ThreadContext context) {
            return pluginType;
        }

        @Override
        protected IRubyObject getInnerWriter(final ThreadContext context) {
            return writerWrapper;
        }

        @Override
        protected IRubyObject doWrite(final ThreadContext context, final IRubyObject event,
            final IRubyObject reason) {
            if (hasOpenWriter()) {
                try {
                    innerWriter.writeEntry(
                        ((JrubyEventExtLibrary.RubyEvent) event).getEvent(),
                            pluginTypeString, pluginIdString, reason.asJavaString()
                    );
                } catch (final IOException ex) {
                    throw new IllegalStateException(ex);
                }
            }
            return context.nil;
        }

        @Override
        protected IRubyObject doClose(final ThreadContext context) {
            if (hasOpenWriter()) {
                innerWriter.close();
            }
            return context.nil;
        }

        @Override
        protected RubyBoolean open(final ThreadContext context) {
            return context.runtime.newBoolean(hasOpenWriter());
        }

        private boolean hasOpenWriter() {
            return innerWriter != null && innerWriter.isOpen();
        }
    }
}
