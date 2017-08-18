package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

/**
 * Witness for the set of pipelines.
 */
@JsonSerialize(using = PipelinesWitness.Serializer.class)
final public class PipelinesWitness implements SerializableWitness {

    private final Map<String, PipelineWitness> pipelines;

    private final static String KEY = "pipelines";
    private static final Serializer SERIALIZER = new Serializer();

    /**
     * Constructor.
     */
    public PipelinesWitness() {
        this.pipelines = new ConcurrentHashMap<>();
    }

    /**
     * Get a uniquely named pipeline witness. If one does not exist, it will be created.
     *
     * @param name The name of the pipeline.
     * @return the {@link PipelineWitness} identified by the given name.
     */
    public PipelineWitness pipeline(String name) {
        return pipelines.computeIfAbsent(name, k -> new PipelineWitness(k));
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        SERIALIZER.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson serializer.
     */
    static class Serializer extends StdSerializer<PipelinesWitness> {

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(PipelinesWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<PipelinesWitness> t) {
            super(t);
        }

        @Override
        public void serialize(PipelinesWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        void innerSerialize(PipelinesWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeObjectFieldStart(KEY);
            for (Map.Entry<String, PipelineWitness> entry : witness.pipelines.entrySet()) {
                entry.getValue().genJson(gen, provider);
            }
            gen.writeEndObject();
        }
    }

}
