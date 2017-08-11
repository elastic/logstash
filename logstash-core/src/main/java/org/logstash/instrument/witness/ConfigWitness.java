package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.BooleanGauge;
import org.logstash.instrument.metrics.gauge.LongGauge;

import java.io.IOException;

/**
 * The witness for configuration.
 */
@JsonSerialize(using = ConfigWitness.Serializer.class)
final public class ConfigWitness implements SerializableWitness {

    private final BooleanGauge deadLetterQueueEnabled;
    private final BooleanGauge configReloadAutomatic;
    private final LongGauge batchSize;
    private final LongGauge workers;
    private final LongGauge batchDelay;
    private final LongGauge configReloadInterval;
    private final Snitch snitch;
    private final static String KEY = "config";
    private static final Serializer SERIALIZER = new Serializer();


    /**
     * Constructor.
     */
    public ConfigWitness() {
        deadLetterQueueEnabled = new BooleanGauge("dead_letter_queue_enabled");
        configReloadAutomatic = new BooleanGauge("config_reload_automatic");
        batchSize = new LongGauge("batch_size");
        workers = new LongGauge("workers");
        batchDelay = new LongGauge("batch_delay");
        configReloadInterval = new LongGauge("config_reload_interval");
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

            MetricSerializer<Metric<Long>> longSerializer = MetricSerializer.Get.longSerializer(gen);
            MetricSerializer<Metric<Boolean>> booleanSerializer = MetricSerializer.Get.booleanSerializer(gen);

            longSerializer.serialize(witness.batchSize);
            longSerializer.serialize(witness.workers);
            longSerializer.serialize(witness.batchDelay);
            longSerializer.serialize(witness.configReloadInterval);
            booleanSerializer.serialize(witness.configReloadAutomatic);
            booleanSerializer.serialize(witness.deadLetterQueueEnabled);
            gen.writeEndObject();
        }
    }

    /**
     * The snitch for the errors. Used to retrieve discrete metric values.
     */
    public static class Snitch {
        private final ConfigWitness witness;

        Snitch(ConfigWitness witness) {
            this.witness = witness;
        }


        /**
         * Gets the configured batch delay
         *
         * @return the batch delay
         */
        public long batchDelay() {
            return witness.batchDelay.getValue();
        }


        /**
         * Gets the configured batch size
         *
         * @return the batch size
         */
        public long batchSize() {
            return witness.batchSize.getValue();
        }

        /**
         * Gets if the reload automatic is configured
         *
         * @return true if configured for automatic, false otherwise
         */
        public boolean configReloadAutomatic() {
            return witness.configReloadAutomatic.getValue();
        }

        /**
         * Gets the configured reload interval
         *
         * @return the configured reload interval
         */
        public long configReloadInterval() {
            return witness.configReloadInterval.getValue();
        }

        /**
         * Gets if the dead letter queue is configured to be enabled
         *
         * @return true if the dead letter queue is configured to be enabled, false otherwise
         */
        public boolean deadLetterQueueEnabled() {
            return witness.deadLetterQueueEnabled.getValue();
        }

        /**
         * Gets the number of configured workers
         *
         * @return the configured number of workers.
         */
        public long workers() {
            return witness.workers.getValue();
        }


    }


}
