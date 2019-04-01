package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.PluginConfigSpec;
import org.jruby.RubySymbol;
import org.jruby.runtime.ThreadContext;
import org.logstash.RubyUtil;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.counter.LongCounter;

import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Map;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

public class JavaCodecDelegator implements Codec {

    public static final RubySymbol ENCODE_KEY = RubyUtil.RUBY.newSymbol("encode");
    public static final RubySymbol DECODE_KEY = RubyUtil.RUBY.newSymbol("decode");
    public static final RubySymbol IN_KEY = RubyUtil.RUBY.newSymbol("writes_in");

    private final Codec codec;

    protected final AbstractNamespacedMetricExt metricEncode;

    protected final AbstractNamespacedMetricExt metricDecode;

    protected final LongCounter encodeMetricIn;

    protected final LongCounter encodeMetricTime;

    protected final LongCounter decodeMetricIn;

    protected final LongCounter decodeMetricOut;

    protected final LongCounter decodeMetricTime;


    public JavaCodecDelegator(final AbstractNamespacedMetricExt metric,
                               final Codec codec) {
        this.codec = codec;

        final ThreadContext context = RubyUtil.RUBY.getCurrentContext();
        final AbstractNamespacedMetricExt namespacedMetric =
            metric.namespace(context, RubyUtil.RUBY.newSymbol(codec.getId()));
        synchronized(namespacedMetric.getMetric()) {
            metricEncode = namespacedMetric.namespace(context, ENCODE_KEY);
            encodeMetricIn = LongCounter.fromRubyBase(metricEncode, IN_KEY);
            encodeMetricTime = LongCounter.fromRubyBase(metricEncode, MetricKeys.DURATION_IN_MILLIS_KEY);

            metricDecode = namespacedMetric.namespace(context, DECODE_KEY);
            decodeMetricIn = LongCounter.fromRubyBase(metricDecode, IN_KEY);
            decodeMetricOut = LongCounter.fromRubyBase(metricDecode, MetricKeys.OUT_KEY);
            decodeMetricTime = LongCounter.fromRubyBase(metricDecode, MetricKeys.DURATION_IN_MILLIS_KEY);

            namespacedMetric.gauge(context, MetricKeys.NAME_KEY, RubyUtil.RUBY.newString(codec.getName()));
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
    public boolean encode(final Event event, final ByteBuffer buffer) throws EncodeException {
        encodeMetricIn.increment();

        final long start = System.nanoTime();

        final boolean ret = codec.encode(event, buffer);

        decodeMetricTime.increment(TimeUnit.MILLISECONDS.convert(System.nanoTime() - start, TimeUnit.NANOSECONDS));

        return ret;
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
