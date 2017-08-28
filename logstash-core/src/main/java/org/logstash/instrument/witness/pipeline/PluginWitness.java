package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.jruby.RubySymbol;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.counter.CounterMetric;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.instrument.metrics.gauge.GaugeMetric;
import org.logstash.instrument.metrics.gauge.LazyDelegatingGauge;
import org.logstash.instrument.metrics.gauge.TextGauge;
import org.logstash.instrument.witness.MetricSerializer;
import org.logstash.instrument.witness.SerializableWitness;

import java.io.IOException;
import java.util.Collections;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Witness for a single plugin.
 */
@JsonSerialize(using = PluginWitness.Serializer.class)
public class PluginWitness implements SerializableWitness {

    private final EventsWitness eventsWitness;
    private final PluginWitness.CustomWitness customWitness;
    private final TextGauge id;
    private final TextGauge name;
    private final Snitch snitch;

    /**
     * Constructor.
     *
     * @param id The unique identifier for this plugin.
     */
    public PluginWitness(String id) {
        eventsWitness = new EventsWitness();
        customWitness = new PluginWitness.CustomWitness();
        this.id = new TextGauge("id", id);
        this.name = new TextGauge("name");
        this.snitch = new Snitch(this);
    }

    /**
     * Get a reference to the associated events witness.
     *
     * @return the associated {@link EventsWitness}
     */
    public EventsWitness events() {
        return eventsWitness;
    }

    /**
     * Sets the name of this plugin.
     *
     * @param name the name of this plugin.
     * @return an instance of this witness (to allow method chaining)
     */
    public PluginWitness name(String name) {
        this.name.set(name);
        return this;
    }

    /**
     * Get a reference to the associated custom witness
     *
     * @return the {@link PluginWitness.CustomWitness}
     */
    public PluginWitness.CustomWitness custom() {
        return this.customWitness;
    }

    /**
     * Get a reference to associated snitch to get discrete metric values.
     *
     * @return the associate {@link Snitch}
     */
    public Snitch snitch() {
        return snitch;
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        Serializer.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson JSON serializer.
     */
    public static final class Serializer extends StdSerializer<PluginWitness> {

        private static final long serialVersionUID = 1L;

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(PluginWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<PluginWitness> t) {
            super(t);
        }

        @Override
        public void serialize(PluginWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        static void innerSerialize(PluginWitness witness, JsonGenerator gen,
            SerializerProvider provider) throws IOException {
            MetricSerializer<Metric<String>> stringSerializer = MetricSerializer.Get.stringSerializer(gen);
            MetricSerializer<Metric<Long>> longSerializer = MetricSerializer.Get.longSerializer(gen);
            stringSerializer.serialize(witness.id);
            witness.events().genJson(gen, provider);
            stringSerializer.serialize(witness.name);
            for (GaugeMetric<Object, Object> gauge : witness.customWitness.gauges.values()) {
                gen.writeObjectField(gauge.getName(), gauge.getValue());
            }
            for (CounterMetric<Long> counter : witness.customWitness.counters.values()) {
                longSerializer.serialize(counter);
            }
        }
    }

    /**
     * A custom witness that we can hand off to plugin's to contribute to the metrics
     */
    public static final class CustomWitness {

        private final Snitch snitch;

        /**
         * private Constructor - not for external instantiation
         */
        private CustomWitness() {
            this.snitch = new Snitch(this);
        }

        private final Map<String, GaugeMetric<Object, Object>> gauges = new ConcurrentHashMap<>();
        private final Map<String, CounterMetric<Long>> counters = new ConcurrentHashMap<>();

        /**
         * Set that gauge value
         *
         * @param key   the {@link RubySymbol} for the key of this gauge. Note - internally this will be converted to a {@link String}
         * @param value The value of the Gauge. This allows for any {@link Object} type, unless text or numeric type, there is no guarantees of proper serialization.
         */
        public void gauge(RubySymbol key, Object value) {
            gauge(key.asJavaString(), value);
        }

        /**
         * Set that gauge value
         *
         * @param key   the {@link String} for the key of this gauge. Note - internally this will be converted to a {@link String}
         * @param value The value of the Gauge. This allows for any {@link Object} type, unless text or numeric type, there is no guarantees of proper serialization.
         */
        public void gauge(String key, Object value) {
            GaugeMetric<Object, Object> gauge = gauges.get(key);
            if (gauge != null) {
                gauge.set(value);
            } else {
                gauge = new LazyDelegatingGauge(key, value);
                gauges.put(key, gauge);
            }
        }

        /**
         * Increments the underlying counter for this {@link RubySymbol} by 1.
         *
         * @param key the {@link RubySymbol} key of the counter to increment. Note - internally this will be converted to a {@link String}
         */
        public void increment(RubySymbol key) {
            increment(key.asJavaString());
        }

        /**
         * Increments the underlying counter for this {@link RubySymbol} by 1.
         *
         * @param key the {@link String} key of the counter to increment. Note - internally this will be converted to a {@link String}
         */
        public void increment(String key) {
            increment(key, 1);
        }

        /**
         * Increments the underlying counter for this {@link RubySymbol} by the given value.
         *
         * @param key the {@link RubySymbol} key of the counter to increment. Note - internally this will be converted to a {@link String}
         * @param by the amount to increment by
         */
        public void increment(RubySymbol key, long by) {
            increment(key.asJavaString(), by);
        }

        /**
         * Increments the underlying counter for this {@link RubySymbol} by the given value.
         *
         * @param key the {@link String} key of the counter to increment. Note - internally this will be converted to a {@link String}
         * @param by the amount to increment by
         */
        public void increment(String key, long by) {
            CounterMetric<Long> counter = counters.get(key);
            if (counter != null) {
                counter.increment(by);
            } else {
                counter = new LongCounter(key);
                counter.increment();
                counters.put(key, counter);
            }
        }

        /**
         * Get a reference to associated snitch to get discrete metric values.
         *
         * @return the associate {@link Snitch}
         */
        public Snitch snitch() {
            return snitch;
        }

        /**
         * Snitch for a plugin. Provides discrete metric values.
         */
        public static final class Snitch {

            private final PluginWitness.CustomWitness witness;

            /**
             * Construtor
             *
             * @param witness the witness
             */
            private Snitch(PluginWitness.CustomWitness witness) {
                this.witness = witness;
            }

            /**
             * Get the underlying {@link GaugeMetric}.  May call {@link GaugeMetric#getType()} to get the underlying type.
             *
             * @param key the key/name of the {@link GaugeMetric}.
             * @return the {@link GaugeMetric}  May return {@code null}
             */
            public GaugeMetric gauge(String key) {
                return witness.gauges.get(key);
            }

            /**
             * Gets the full set of custom {@link GaugeMetric}
             *
             * @return the map of all of the {@link GaugeMetric}, keyed by the associated {@link GaugeMetric} key/name
             */
            public Map<String, GaugeMetric<?, ?>> gauges() {
                return Collections.unmodifiableMap(witness.gauges);
            }

            /**
             * Get the custom Counter. May call {@link CounterMetric#getType()} to get the underlying type.
             *
             * @param key the key/name of the {@link CounterMetric}
             * @return the {@link CounterMetric} for the given key. May return {@code null}
             */
            public CounterMetric<?> counter(String key) {
                return witness.counters.get(key);
            }

            /**
             * Gets the full set of the custom {@link CounterMetric}
             *
             * @return the map of all of the {@link CounterMetric}, keyed by the associated {@link CounterMetric} key/name
             */
            public Map<String, CounterMetric<?>> counters() {
                return Collections.unmodifiableMap(witness.counters);
            }
        }
    }

    /**
     * Snitch for a plugin. Provides discrete metric values.
     */
    public static final class Snitch {

        private final PluginWitness witness;

        private Snitch(PluginWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the id for this plugin.
         *
         * @return the id
         */
        public String id() {
            return witness.id.getValue();
        }

        /**
         * Gets the name of this plugin
         *
         * @return the name
         */
        public String name() {
            return witness.name.getValue();
        }

    }
}
