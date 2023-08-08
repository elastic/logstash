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
import java.util.Map;
import java.util.concurrent.BlockingQueue;

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;

@JRubyClass(name = "MemoryWriteClient")
public final class JrubyMemoryWriteClientExt extends JRubyAbstractQueueWriteClientExt {

    private static final long serialVersionUID = 1L;

    private transient BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue;

    public JrubyMemoryWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyMemoryWriteClientExt(final Ruby runtime, final RubyClass metaClass,
                                      final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue) {
        super(runtime, metaClass);
        this.queue = queue;
    }

    public static JrubyMemoryWriteClientExt create(
            final BlockingQueue<JrubyEventExtLibrary.RubyEvent> queue) {
        return new JrubyMemoryWriteClientExt(RubyUtil.RUBY,
                RubyUtil.MEMORY_WRITE_CLIENT_CLASS, queue);
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt doPush(final ThreadContext context,
                                                      final JrubyEventExtLibrary.RubyEvent event) throws InterruptedException {
        queue.put(event);
        return this;
    }

    @Override
    public JRubyAbstractQueueWriteClientExt doPushBatch(final ThreadContext context,
                                                        final Collection<JrubyEventExtLibrary.RubyEvent> batch) throws InterruptedException {
        LsQueueUtils.addAll(queue, batch);
        return this;
    }

    @Override
    public void push(Map<String, Object> event) {
        try {
            queue.put(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, new Event(event)));
        } catch (InterruptedException e) {
            throw new IllegalStateException(e);
        }
    }
}
