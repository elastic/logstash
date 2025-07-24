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

import java.util.Map;
import java.util.concurrent.BlockingQueue;
import java.util.concurrent.TimeUnit;

import io.opentelemetry.api.trace.Span;
import io.opentelemetry.api.trace.SpanKind;
import io.opentelemetry.context.Context;
import io.opentelemetry.context.Scope;
import io.opentelemetry.context.propagation.ContextPropagators;
import io.opentelemetry.context.propagation.TextMapGetter;
import io.opentelemetry.context.propagation.TextMapPropagator;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyClass;
import org.jruby.anno.JRubyClass;
import org.logstash.Event;
import org.logstash.OTelUtil;
import org.logstash.RubyUtil;
import org.logstash.common.LsQueueUtils;
import org.logstash.execution.MemoryReadBatch;
import org.logstash.execution.QueueBatch;
import org.logstash.execution.QueueReadClientBase;

import javax.annotation.Nullable;

import static org.logstash.OTelUtil.tracer;

/**
 * JRuby extension to provide an implementation of queue client for InMemory queue
 * */
@JRubyClass(name = "MemoryReadClient", parent = "QueueReadClientBase")
public final class JrubyMemoryReadClientExt extends QueueReadClientBase {

    private static final Logger LOGGER = LogManager.getLogger(JrubyMemoryReadClientExt.class);

    private static final long serialVersionUID = 1L;

    @SuppressWarnings("unchecked")
    public static final TextMapGetter<Event> JAVA_EVENT_CARRIER_GETTER = new TextMapGetter<>() {

        @Override
        public Iterable<String> keys(Event event) {
            Map<String, String> otelContextMap = retrieveContextMapFromMetadata(event);
            return otelContextMap.keySet();
        }

        private Map<String, String> retrieveContextMapFromMetadata(Event event) {
            // TODO handle error cases, like no meta, no otel_context map, type conversion etc
            return (Map<String, String>) event.getMetadata().get(OTelUtil.METADATA_OTEL_CONTEXT);
        }

        @Nullable
        @Override
        public String get(@Nullable Event event, String s) {
            Map<String, String> otelContextMap = retrieveContextMapFromMetadata(event);
            return otelContextMap.get(s);
        }
    };

    @SuppressWarnings({"rawtypes", "serial"}) private BlockingQueue queue;

    public JrubyMemoryReadClientExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @SuppressWarnings("rawtypes")
    private JrubyMemoryReadClientExt(final Ruby runtime, final RubyClass metaClass,
                                     BlockingQueue queue, int batchSize, int waitForMillis) {
        super(runtime, metaClass);
        this.queue = queue;
        this.batchSize = batchSize;
        this.waitForNanos = TimeUnit.NANOSECONDS.convert(waitForMillis, TimeUnit.MILLISECONDS);
        this.waitForMillis = waitForMillis;
    }

    @SuppressWarnings("rawtypes")
    public static JrubyMemoryReadClientExt create(BlockingQueue queue, int batchSize,
                                                  int waitForMillis) {
        return new JrubyMemoryReadClientExt(RubyUtil.RUBY,
                RubyUtil.MEMORY_READ_CLIENT_CLASS, queue, batchSize, waitForMillis);
    }

    @Override
    public void close() {
        // no-op
    }

    @Override
    public boolean isEmpty() {
        return queue.isEmpty();
    }

    @Override
    public QueueBatch newBatch() {
        return MemoryReadBatch.create();
    }

    @Override
    @SuppressWarnings("unchecked")
    public QueueBatch readBatch() throws InterruptedException {
        final MemoryReadBatch batch = MemoryReadBatch.create(LsQueueUtils.drain(queue, batchSize, waitForNanos));
        recordQueueSpans(batch);
        startMetrics(batch);
        return batch;
    }

    private void recordQueueSpans(MemoryReadBatch batch) {
        for (JrubyEventExtLibrary.RubyEvent e : batch.events()) {
            Event javaEvent = e.getEvent();

            // deserialize the otel context map from event carrier
            ContextPropagators propagators = OTelUtil.openTelemetry.getPropagators();
            TextMapPropagator textMapPropagator = propagators.getTextMapPropagator();

            // Extract and store the propagated span's SpanContext and other available concerns
            // in the specified Context.
            Context context = textMapPropagator.extract(Context.current(), javaEvent, JAVA_EVENT_CARRIER_GETTER);

            Span span = tracer.spanBuilder("pipeline.queue")
                    .setParent(context)
                    .setSpanKind(SpanKind.SERVER).startSpan();

            span.makeCurrent();
            span.end();
        }
    }
}
