package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.witness.configuration.ConfigWitness;
import org.logstash.instrument.witness.SerializableWitness;

import java.io.IOException;

/**
 * A single pipeline witness.
 */
@JsonSerialize(using = PipelineWitness.Serializer.class)
final public class PipelineWitness implements SerializableWitness {

    private final ReloadWitness reloadWitness;
    private final EventsWitness eventsWitness;
    private final ConfigWitness configWitness;
    private final PluginsWitness pluginsWitness;
    private final QueueWitness queueWitness;
    private final DeadLetterQueueWitness deadLetterQueueWitness;
    private final String KEY;
    private static final Serializer SERIALIZER = new Serializer();

    /**
     * Constructor.
     *
     * @param pipelineName The uniquely identifying name of the pipeline.
     */
    public PipelineWitness(String pipelineName) {
        this.KEY = pipelineName;
        this.reloadWitness = new ReloadWitness();
        this.eventsWitness = new EventsWitness();
        this.configWitness = new ConfigWitness();
        this.pluginsWitness = new PluginsWitness();
        this.queueWitness = new QueueWitness();
        this.deadLetterQueueWitness = new DeadLetterQueueWitness();
    }

    /**
     * Get a reference to associated config witness
     *
     * @return the associated {@link ConfigWitness}
     */
    public ConfigWitness config() {
        return configWitness;
    }

    /**
     * Get a reference to the associated dead letter queue witness
     * @return The associated {@link DeadLetterQueueWitness}
     */
    public DeadLetterQueueWitness dlq() {
        return deadLetterQueueWitness;
    }

    /**
     * Get a reference to associated events witness
     *
     * @return the associated {@link EventsWitness}
     */
    public EventsWitness events() {
        return eventsWitness;
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     *
     * @param id the id of the filter
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness filters(String id) {
        return pluginsWitness.filters(id);
    }

    /**
     * Forgets all events for this witness.
     */
    public void forgetEvents() {
        events().forgetAll();
    }

    /**
     * Forgets all plugins for this witness.
     */
    public void forgetPlugins() {
        plugins().forgetAll();
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     *
     * @param id the id of the input
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness inputs(String id) {
        return pluginsWitness.inputs(id);
    }

    /**
     * Gets the {@link PluginWitness} for the given id, creates the associated {@link PluginWitness} if needed
     *
     * @param id the id of the output
     * @return the associated {@link PluginWitness} (for method chaining)
     */
    public PluginWitness outputs(String id) {
        return pluginsWitness.outputs(id);
    }

    /**
     * Get a reference to associated plugins witness
     *
     * @return the associated {@link PluginsWitness}
     */
    public PluginsWitness plugins() {
        return pluginsWitness;
    }

    /**
     * Get a reference to associated reload witness
     *
     * @return the associated {@link ReloadWitness}
     */
    public ReloadWitness reloads() {
        return reloadWitness;
    }

    /**
     * Get a reference to associated queue witness
     *
     * @return the associated {@link QueueWitness}
     */
    public QueueWitness queue() {
        return queueWitness;
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        SERIALIZER.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson serializer.
     */
    static class Serializer extends StdSerializer<PipelineWitness> {

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(PipelineWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<PipelineWitness> t) {
            super(t);
        }

        @Override
        public void serialize(PipelineWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        void innerSerialize(PipelineWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeObjectFieldStart(witness.KEY);
            witness.events().genJson(gen, provider);
            witness.plugins().genJson(gen, provider);
            witness.reloads().genJson(gen, provider);
            witness.queue().genJson(gen, provider);
            if (witness.config().snitch().deadLetterQueueEnabled()) {
                witness.dlq().genJson(gen, provider);
            }
            gen.writeEndObject();
        }
    }
}
