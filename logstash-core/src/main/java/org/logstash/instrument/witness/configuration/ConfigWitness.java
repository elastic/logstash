package org.logstash.instrument.witness.configuration;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.BooleanGauge;
import org.logstash.instrument.metrics.gauge.NumberGauge;
import org.logstash.instrument.metrics.gauge.TextGauge;
import org.logstash.instrument.witness.MetricSerializer;
import org.logstash.instrument.witness.SerializableWitness;

import java.io.IOException;

/**
 * The witness for configuration.
 */
@JsonSerialize(using = ConfigWitness.Serializer.class)
final public class ConfigWitness implements SerializableWitness {

    private final BooleanGauge deadLetterQueueEnabled;
    private final BooleanGauge configReloadAutomatic;
    private final NumberGauge batchSize;
    private final NumberGauge workers;
    private final NumberGauge batchDelay;
    private final NumberGauge configReloadInterval;
    private final TextGauge deadLetterQueuePath;
    private final Snitch snitch;
    private final static String KEY = "config";
    private static final Serializer SERIALIZER = new Serializer();


    /**
     * Constructor.
     */
    public ConfigWitness() {
        deadLetterQueueEnabled = new BooleanGauge("dead_letter_queue_enabled");
        configReloadAutomatic = new BooleanGauge("config_reload_automatic");
        batchSize = new NumberGauge("batch_size");
        workers = new NumberGauge("workers");
        batchDelay = new NumberGauge("batch_delay");
        configReloadInterval = new NumberGauge("config_reload_interval");
        deadLetterQueuePath = new TextGauge("dead_letter_queue_path");
        snitch = new Snitch(this);
    }

    /**
     * Sets the configured batch delay
     *
     * @param delay the configured batch delay
     */
    public void batchDelay(long delay) {
        batchDelay.set(delay);
    }

    /**
     * Sets the configured batch size
     *
     * @param size the configured batch size
     */
    public void batchSize(long size) {
        batchSize.set(size);
    }

    /**
     * Flag to determine if the configuration is configured for auto reload
     *
     * @param isAuto true if the config is set reload, false otherwise
     */
    public void configReloadAutomatic(boolean isAuto) {
        configReloadAutomatic.set(isAuto);
    }

    /**
     * The configured reload interval
     *
     * @param interval the interval between reloads
     */
    public void configReloadInterval(long interval) {
        configReloadInterval.set(interval);
    }

    /**
     * Flag to determine if the dead letter queue is configured to be enabled.
     *
     * @param enabled true if enabled, false otherwise
     */
    public void deadLetterQueueEnabled(boolean enabled) {
        deadLetterQueueEnabled.set(enabled);
    }

    /**
     * The configured path for the dead letter queue.
     *
     * @param path the path used by the dead letter queue
     */
    public void deadLetterQueuePath(String path) {
        deadLetterQueuePath.set(path);
    }

    /**
     * The number of configured workers
     *
     * @param workers the number of configured workers
     */
    public void workers(long workers) {
        this.workers.set(workers);
    }

    /**
     * Get a reference to associated snitch to get discrete metric values.
     *
     * @return the associate {@link Snitch}
     */
    public Snitch snitch() {
        return this.snitch;
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        SERIALIZER.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson serializer.
     */
    static class Serializer extends StdSerializer<ConfigWitness> {

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(ConfigWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<ConfigWitness> t) {
            super(t);
        }

        @Override
        public void serialize(ConfigWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        void innerSerialize(ConfigWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeObjectFieldStart(KEY);

            MetricSerializer<Metric<Number>> numberSerializer = MetricSerializer.Get.numberSerializer(gen);
            MetricSerializer<Metric<Boolean>> booleanSerializer = MetricSerializer.Get.booleanSerializer(gen);
            MetricSerializer<Metric<String>> stringSerializer = MetricSerializer.Get.stringSerializer(gen);

            numberSerializer.serialize(witness.batchSize);
            numberSerializer.serialize(witness.workers);
            numberSerializer.serialize(witness.batchDelay);
            numberSerializer.serialize(witness.configReloadInterval);
            booleanSerializer.serialize(witness.configReloadAutomatic);
            booleanSerializer.serialize(witness.deadLetterQueueEnabled);
            stringSerializer.serialize(witness.deadLetterQueuePath);
            gen.writeEndObject();
        }
    }

    /**
     * The snitch for the errors. Used to retrieve discrete metric values.
     */
    public class Snitch {
        private final ConfigWitness witness;

        private Snitch(ConfigWitness witness) {
            this.witness = witness;
        }


        /**
         * Gets the configured batch delay
         *
         * @return the batch delay. May be {@code null}
         */
        public Number batchDelay() {
            return witness.batchDelay.getValue();
        }


        /**
         * Gets the configured batch size
         *
         * @return the batch size. May be {@code null}
         */
        public Number batchSize() {
            return witness.batchSize.getValue();
        }

        /**
         * Gets if the reload automatic is configured
         *
         * @return true if configured for automatic, false otherwise
         */
        public boolean configReloadAutomatic() {
            Boolean reload = witness.configReloadAutomatic.getValue();
            return reload == null ? false : reload;
        }

        /**
         * Gets the configured reload interval
         *
         * @return the configured reload interval. May be {@code null}
         */
        public Number configReloadInterval() {
            return witness.configReloadInterval.getValue();
        }

        /**
         * Gets if the dead letter queue is configured to be enabled
         *
         * @return true if the dead letter queue is configured to be enabled, false otherwise
         */
        public boolean deadLetterQueueEnabled() {
            Boolean enabled = witness.deadLetterQueueEnabled.getValue();
            return enabled == null ? false : enabled;
        }

        /**
         * Gets the path that the dead letter queue is configured.
         *
         * @return the configured path for the dead letter queue. May be {@code null}
         */
        public String deadLetterQueuePath() {
            return witness.deadLetterQueuePath.getValue();
        }

        /**
         * Gets the number of configured workers
         *
         * @return the configured number of workers. May be {@code null}
         */
        public Number workers() {
            return witness.workers.getValue();
        }
    }
}
