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

import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.Event;
import org.logstash.RubyUtil;
import org.logstash.ackedqueue.ext.JRubyAckedQueueExt;

@JRubyClass(name = "AckedWriteClient")
public final class JrubyAckedWriteClientExt extends JRubyAbstractQueueWriteClientExt {

    private static final long serialVersionUID = 1L;

    private JRubyAckedQueueExt queue;

    public static JrubyAckedWriteClientExt create(final JRubyAckedQueueExt queue) {
        return new JrubyAckedWriteClientExt(RubyUtil.RUBY, RubyUtil.ACKED_WRITE_CLIENT_CLASS, queue);
    }

    public JrubyAckedWriteClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    private JrubyAckedWriteClientExt(final Ruby runtime, final RubyClass metaClass,
                                     final JRubyAckedQueueExt queue) {
        super(runtime, metaClass);
        this.queue = queue;
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt doPush(final ThreadContext context,
                                                      final JrubyEventExtLibrary.RubyEvent event) {
        queue.rubyWrite(context, event.getEvent());
        return this;
    }

    @Override
    protected JRubyAbstractQueueWriteClientExt doPushBatch(final ThreadContext context,
                                                           final Collection<JrubyEventExtLibrary.RubyEvent> batch) {
        for (final IRubyObject event : batch) {
            queue.rubyWrite(context, ((JrubyEventExtLibrary.RubyEvent) event).getEvent());
        }
        return this;
    }

    @Override
    public void push(Map<String, Object> event) {
        queue.write(new Event(event));
    }

}
