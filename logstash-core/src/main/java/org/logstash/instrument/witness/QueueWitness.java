package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.metrics.gauge.TextGauge;

import java.io.IOException;

/**
 * Witness for the queue.
 */
@JsonSerialize(using = QueueWitness.Serializer.class)
final public class QueueWitness implements SerializableWitness {

    private final TextGauge type;
    private final Snitch snitch;
    private final static String KEY = "queue";
    private static final Serializer SERIALIZER = new Serializer();

    /**
     * Constructor.
     */
    public QueueWitness() {
        type = new TextGauge("type");
        snitch = new Snitch(this);
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
     * Sets the type of the queue.
     *
     * @param type The type of the queue.
     */
    public void type(String type) {
        this.type.set(type);
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        SERIALIZER.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson serializer.
     */
    public static class Serializer extends StdSerializer<QueueWitness> {
        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(QueueWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<QueueWitness> t) {
            super(t);
        }

        @Override
        public void serialize(QueueWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        void innerSerialize(QueueWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeObjectFieldStart(KEY);
            MetricSerializer.Get.stringSerializer(gen).serialize(witness.type);
            gen.writeEndObject();
        }
    }

    /**
     * Snitch for queue. Provides discrete metric values.
     */
    public static class Snitch {

        private final QueueWitness witness;

        Snitch(QueueWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the type of queue
         *
         * @return the queue type.
         */
        public String type() {
            return witness.type.getValue();
        }

    }
}
