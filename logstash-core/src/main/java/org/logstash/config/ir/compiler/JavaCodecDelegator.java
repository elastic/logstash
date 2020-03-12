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


package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.CounterMetric;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.Metric;
import co.elastic.logstash.api.NamespacedMetric;
import co.elastic.logstash.api.PluginConfigSpec;
import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

public class JavaCodecDelegator implements Codec {

    public static final String ENCODE_KEY = "encode";
    public static final String DECODE_KEY = "decode";
    public static final String IN_KEY = "writes_in";

    private final Codec codec;

    protected final CounterMetric encodeMetricIn;

    protected final CounterMetric encodeMetricTime;

    protected final CounterMetric decodeMetricIn;

    protected final CounterMetric decodeMetricOut;

    protected final CounterMetric decodeMetricTime;


    public JavaCodecDelegator(final Context context, final Codec codec) {
        this.codec = codec;

        final NamespacedMetric metric = context.getMetric(codec);

        synchronized(metric.root()) {
            metric.gauge(MetricKeys.NAME_KEY.asJavaString(), codec.getName());

            final NamespacedMetric encodeMetric = metric.namespace(ENCODE_KEY);
            encodeMetricIn = encodeMetric.counter(IN_KEY);
            encodeMetricTime = encodeMetric.counter(MetricKeys.DURATION_IN_MILLIS_KEY.asJavaString());

            final NamespacedMetric decodeMetric = metric.namespace(DECODE_KEY);
            decodeMetricIn = decodeMetric.counter(IN_KEY);
            decodeMetricOut = decodeMetric.counter(MetricKeys.OUT_KEY.asJavaString());
            decodeMetricTime = decodeMetric.counter(MetricKeys.DURATION_IN_MILLIS_KEY.asJavaString());
        }
    }

    @Override
    public void decode(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
        decodeMetricIn.increment();

        final long start = System.nanoTime();

        codec.decode(buffer, (event) -> {
            decodeMetricOut.increment();
            eventConsumer.accept(event);
        });

        decodeMetricTime.increment(TimeUnit.MILLISECONDS.convert(System.nanoTime() - start, TimeUnit.NANOSECONDS));
    }

    @Override
    public void flush(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
        decodeMetricIn.increment();

        final long start = System.nanoTime();

        codec.flush(buffer, (event) -> {
            decodeMetricOut.increment();
            eventConsumer.accept(event);
        });

        decodeMetricTime.increment(TimeUnit.MILLISECONDS.convert(System.nanoTime() - start, TimeUnit.NANOSECONDS));
    }

    @Override
    public void encode(final Event event, final OutputStream out) throws IOException {
        encodeMetricIn.increment();

        final long start = System.nanoTime();

        codec.encode(event, out);

        decodeMetricTime.increment(TimeUnit.MILLISECONDS.convert(System.nanoTime() - start, TimeUnit.NANOSECONDS));
    }

    @Override
    public Codec cloneCodec() {
        return codec.cloneCodec();
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return codec.configSchema();
    }

    @Override
    public String getName() {
        return codec.getName();
    }

    @Override
    public String getId() {
        return codec.getId();
    }
}
