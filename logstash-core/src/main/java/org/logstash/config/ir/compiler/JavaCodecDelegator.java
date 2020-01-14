package org.logstash.config.ir.compiler;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.CounterMetric;
import co.elastic.logstash.api.Event;
import co.elastic.logstash.api.NamespacedMetric;
import co.elastic.logstash.api.PluginConfigSpec;
import org.logstash.RubyUtil;
import org.logstash.common.SourceWithMetadata;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.MetricKeys;

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


    /**
     * @param context plugin's context to pass through.
     * @param codec the codec plugin's instance.
     * @param source is optional, it's not used when no codec are specified and fallback to default one.
     * */
    public JavaCodecDelegator(final Context context, final Codec codec, SourceWithMetadata source) {
        this.codec = codec;

        final NamespacedMetric metric = context.getMetric(codec);

        synchronized(metric.root()) {
            metric.gauge(MetricKeys.NAME_KEY.asJavaString(), codec.getName());
            if (source != null) {
                NamespacedMetric metricConfigReference = metric.namespace(MetricKeys.CONFIG_REF_KEY.asJavaString());
                metricConfigReference.gauge(MetricKeys.CONFIG_SOURCE_KEY.asJavaString(), RubyUtil.RUBY.newString(source.getId()));
                metricConfigReference.gauge(MetricKeys.CONFIG_LINE_KEY.asJavaString(), RubyUtil.RUBY.newFixnum(source.getLine()));
                metricConfigReference.gauge(MetricKeys.CONFIG_COLUMN_KEY.asJavaString(), RubyUtil.RUBY.newFixnum(source.getColumn()));
            }

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
