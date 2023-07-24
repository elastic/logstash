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


package org.logstash.ext;

import java.util.Collection;

import org.jruby.Ruby;
import org.jruby.RubyBasicObject;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.execution.queue.QueueWriter;

@JRubyClass(name = "AbstractQueueWriteClient")
public abstract class JRubyAbstractQueueWriteClientExt extends RubyBasicObject implements QueueWriter {

    private static final long serialVersionUID = 1L;

    protected JRubyAbstractQueueWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(name = {"push", "<<"}, required = 1)
    public final JRubyAbstractQueueWriteClientExt rubyPush(final ThreadContext context,
                                                           final IRubyObject event) throws InterruptedException {
        doPush(context, (JrubyEventExtLibrary.RubyEvent) event);
        return this;
    }

    @SuppressWarnings("unchecked")
    @JRubyMethod(name = "push_batch", required = 1)
    public final JRubyAbstractQueueWriteClientExt rubyPushBatch(final ThreadContext context,
                                                                final IRubyObject batch) throws InterruptedException {
        doPushBatch(context, (Collection<JrubyEventExtLibrary.RubyEvent>) batch);
        return this;
    }

    protected abstract JRubyAbstractQueueWriteClientExt doPush(ThreadContext context,
                                                               JrubyEventExtLibrary.RubyEvent event) throws InterruptedException;

    protected abstract JRubyAbstractQueueWriteClientExt doPushBatch(ThreadContext context,
                                                                    Collection<JrubyEventExtLibrary.RubyEvent> batch) throws InterruptedException;
}
