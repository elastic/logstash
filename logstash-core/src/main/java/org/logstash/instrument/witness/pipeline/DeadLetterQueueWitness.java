package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.NumberGauge;
import org.logstash.instrument.witness.MetricSerializer;
import org.logstash.instrument.witness.SerializableWitness;

import java.io.IOException;

/**
 * Witness for the Dead Letter Queue
 */
@JsonSerialize(using = DeadLetterQueueWitness.Serializer.class)
public class DeadLetterQueueWitness implements SerializableWitness {

    private static String KEY = "dead_letter_queue";
    private static final Serializer SERIALIZER = new Serializer();
    private final Snitch snitch;
    private final NumberGauge queueSizeInBytes;

    /**
     * Constructor
     */
    public DeadLetterQueueWitness() {
        queueSizeInBytes = new NumberGauge("queue_size_in_bytes");
        snitch = new Snitch(this);
    }

    /**
     * Set the dead letter queue size, represented in bytes
     *
     * @param size the byte size of the queue
     */
    public void queueSizeInBytes(long size) {
        queueSizeInBytes.set(size);
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
    static class Serializer extends StdSerializer<DeadLetterQueueWitness> {

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(DeadLetterQueueWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<DeadLetterQueueWitness> t) {
            super(t);
        }

        @Override
        public void serialize(DeadLetterQueueWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        void innerSerialize(DeadLetterQueueWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeObjectFieldStart(KEY);
            MetricSerializer<Metric<Number>> numberSerializer = MetricSerializer.Get.numberSerializer(gen);
            numberSerializer.serialize(witness.queueSizeInBytes);
            gen.writeEndObject();
        }
    }

    /**
     * The snitch for the dead letter queue. Used to retrieve discrete metric values.
     */
    public class Snitch {
        private final DeadLetterQueueWitness witness;

        private Snitch(DeadLetterQueueWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the queue size in bytes
         *
         * @return the queue size in bytes. May be {@code null}
         */
        public Number queueSizeInBytes() {
            return witness.queueSizeInBytes.getValue();
        }
    }
}
