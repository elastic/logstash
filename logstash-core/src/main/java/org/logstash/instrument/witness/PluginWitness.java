package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.TextGauge;

import java.io.IOException;

/**
 * Witness for a single plugin.
 */
@JsonSerialize(using = PluginWitness.Serializer.class)
public class PluginWitness implements SerializableWitness {

    private final EventsWitness eventsWitness;
    private final TextGauge id;
    private final TextGauge name;
    private final Snitch snitch;
    private static final Serializer SERIALIZER = new Serializer();

    /**
     * Constructor.
     *
     * @param id The unique identifier for this plugin.
     */
    public PluginWitness(String id) {
        eventsWitness = new EventsWitness();
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
     * Get a reference to associated snitch to get discrete metric values.
     *
     * @return the associate {@link Snitch}
     */
    public Snitch snitch() {
        return snitch;
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        SERIALIZER.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson JSON serializer.
     */
    static class Serializer extends StdSerializer<PluginWitness> {

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

        void innerSerialize(PluginWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            MetricSerializer<Metric<String>> stringSerializer = MetricSerializer.Get.stringSerializer(gen);
            stringSerializer.serialize(witness.id);
            witness.events().genJson(gen, provider);
            stringSerializer.serialize(witness.name);
        }
    }

    /**
     * Snitch for a plugin. Provides discrete metric values.
     */
    public class Snitch {

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
