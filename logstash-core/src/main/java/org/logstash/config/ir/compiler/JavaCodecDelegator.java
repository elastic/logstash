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
import co.elastic.logstash.api.NamespacedMetric;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.TimerMetric;
import org.logstash.instrument.metrics.MetricKeys;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Map;
import java.util.function.Consumer;

public class JavaCodecDelegator implements Codec {

    private final Codec codec;

    protected final CounterMetric encodeMetricIn;

    protected final TimerMetric encodeMetricTime;

    protected final CounterMetric decodeMetricIn;

    protected final CounterMetric decodeMetricOut;

    protected final TimerMetric decodeMetricTime;

    public JavaCodecDelegator(final Context context, final Codec codec) {
        this.codec = codec;

        final NamespacedMetric metric = context.getMetric(codec);

        synchronized(metric.root()) {
            metric.gauge(MetricKeys.NAME_KEY.asJavaString(), codec.getName());

            final NamespacedMetric encodeMetric = metric.namespace(MetricKeys.ENCODE_KEY.asJavaString());
            encodeMetricIn = encodeMetric.counter(MetricKeys.WRITES_IN_KEY.asJavaString());
            encodeMetricTime = encodeMetric.timer(MetricKeys.DURATION_IN_MILLIS_KEY.asJavaString());

            final NamespacedMetric decodeMetric = metric.namespace(MetricKeys.DECODE_KEY.asJavaString());
            decodeMetricIn = decodeMetric.counter(MetricKeys.WRITES_IN_KEY.asJavaString());
            decodeMetricOut = decodeMetric.counter(MetricKeys.OUT_KEY.asJavaString());
            decodeMetricTime = decodeMetric.timer(MetricKeys.DURATION_IN_MILLIS_KEY.asJavaString());
        }
    }

    @Override
    public void decode(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
        decodeMetricIn.increment();

        decodeMetricTime.time(() -> codec.decode(buffer, (event) -> {
            decodeMetricOut.increment();
            eventConsumer.accept(event);
        }));
    }

    @Override
    public void flush(final ByteBuffer buffer, final Consumer<Map<String, Object>> eventConsumer) {
        decodeMetricIn.increment();

        decodeMetricTime.time(() -> codec.flush(buffer, (event) -> {
            decodeMetricOut.increment();
            eventConsumer.accept(event);
        }));
    }

    @Override
    public void encode(final Event event, final OutputStream out) throws IOException {
        encodeMetricIn.increment();

        encodeMetricTime.time(() -> codec.encode(event, out));
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
