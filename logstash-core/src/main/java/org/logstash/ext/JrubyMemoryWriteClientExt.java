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
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.BlockingQueue;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.ContextPropagators;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.jruby.runtime.ThreadContext;
import org.logstash.Event;
import org.logstash.OTelUtil;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;

import static org.logstash.OTelUtil.tracer;

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
        Event carrierEvent = event.getEvent();
        propagateOtelContextInEvent(carrierEvent);
        queue.put(event);
        return this;
    }

    @SuppressWarnings("try")
    private static void propagateOtelContextInEvent(Event carrierEvent) {
        Span span = tracer.spanBuilder("pipeline.total").startSpan();
        try (Scope unused = span.makeCurrent()) {
            Span queueSpan = tracer.spanBuilder("pipeline.queue")
                    // TODO
//                .setAttribute(AttributeKey.stringKey("pipeline.id"), "abracadabra")
                    .startSpan();
            propagateContextIntoEvent(carrierEvent, OTelUtil.METADATA_OTEL_FULLCONTEXT, Context.current());

            try (Scope ignored = queueSpan.makeCurrent()) {
                propagateContextIntoEvent(carrierEvent, OTelUtil.METADATA_OTEL_CONTEXT, Context.current());
            }
        }
    }

    private static void propagateContextIntoEvent(Event carrierEvent, String targetEventField, Context context) {
        Map<String, String> otemContextMap = new HashMap<>();
        carrierEvent.getMetadata().put(targetEventField, otemContextMap);
        ContextPropagators propagators = OTelUtil.openTelemetry.getPropagators();
        propagators.getTextMapPropagator().inject(context, carrierEvent,
                (javaEvent, key, value) -> otemContextMap.put(key, value));
    }

    @Override
    public JRubyAbstractQueueWriteClientExt doPushBatch(final ThreadContext context,
                                                        final Collection<JrubyEventExtLibrary.RubyEvent> batch) throws InterruptedException {
        // create new span for each event and propagate in the event itself
        for (JrubyEventExtLibrary.RubyEvent event : batch) {
            Event carrierEvent = event.getEvent();
            propagateOtelContextInEvent(carrierEvent);
        }
        LsQueueUtils.addAll(queue, batch);
        return this;
    }

    @Override
    public void push(Map<String, Object> event) {
        try {
            Event carrierEvent = new Event(event);
            propagateOtelContextInEvent(carrierEvent);
            queue.put(JrubyEventExtLibrary.RubyEvent.newRubyEvent(RubyUtil.RUBY, carrierEvent));
        } catch (InterruptedException e) {
            throw new IllegalStateException(e);
        }
    }
}
