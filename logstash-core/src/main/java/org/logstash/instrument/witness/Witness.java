package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.witness.pipeline.EventsWitness;
import org.logstash.instrument.witness.pipeline.PipelineWitness;
import org.logstash.instrument.witness.pipeline.PipelinesWitness;
import org.logstash.instrument.witness.pipeline.ReloadWitness;

import java.io.IOException;
import java.util.Arrays;

/**
 * <p>Primary entry point for the Witness subsystem. The Witness subsystem is an abstraction for the {@link org.logstash.instrument.metrics.Metric}'s  that watches/witnesses what
 * is happening inside Logstash. </p>
 * <p>Usage example to increment the events counter for the foo input in the main pipeline:
 * {@code Witness.instance().pipeline("main").inputs("foo").events().in(1);}
 * </p>
 * <p>A Witness may be forgetful. Which means that those witnesses may expose a {@code forget()} method to reset underlying metrics back to it's initial state. </p>
 * <p>A Witness may also be a snitch. Which means that those witnesses may expose a {@code snitch()} method to retrieve the underlying metric values without JSON serialization.</p>
 * <p>All Witnesses are capable of serializing their underlying metrics as JSON.</p>
 */
@JsonSerialize(using = Witness.Serializer.class)
final public class Witness implements SerializableWitness {

    private final ReloadWitness reloadWitness;
    private final EventsWitness eventsWitness;
    private final PipelinesWitness pipelinesWitness;

    private static Witness _instance;
    private static final Serializer SERIALIZER = new Serializer();

    /**
     * Constructor. Consumers should use {@link #instance()} method to obtain an instance of this class.
     * <p>THIS IS ONLY TO BE USED BY THE RUBY AGENT</p>
     */
    public Witness() {
        this.reloadWitness = new ReloadWitness();
        this.eventsWitness = new EventsWitness();
        this.pipelinesWitness = new PipelinesWitness();
    }

    /**
     * This is a dirty hack since the {@link Witness} needs to mirror the Ruby agent's lifecycle which, at least for testing, can mean more then 1 instance per JVM, but only 1
     * active instance at any time.  Exposing this allows Ruby to create the instance for use in it's agent constructor, then set it here for all to use as a singleton.
     * <p>THIS IS ONLY TO BE USED BY THE RUBY AGENT</p>
     *
     * @param __instance The instance of the {@link Witness} to use as the singleton instance that mirror's the agent's lifecycle.
     */
    public static void setInstance(Witness __instance) {
        _instance = __instance;
    }

    /**
     * Obtain the singleton instance of the {@link Witness}
     *
     * @return the singleton instance of the {@link Witness}
     * @throws IllegalStateException if attempted to be used before being set.
     */
    public static Witness instance() {
        if (_instance == null) {
            throw new IllegalStateException("The stats witness instance must be set before it used. Called from: " + Arrays.toString(new Throwable().getStackTrace()));
        }
        return _instance;
    }

    public EventsWitness events() {
        return eventsWitness;
    }

    /**
     * Obtain a reference to the associated reload witness.
     *
     * @return The associated {@link ReloadWitness}
     */
    public ReloadWitness reloads() {
        return reloadWitness;
    }

    /**
     * Obtain a reference to the associated pipelines witness. Consumers may use {@link #pipeline(String)} as a shortcut to this method.
     *
     * @return The associated {@link PipelinesWitness}
     */
    public PipelinesWitness pipelines() {
        return pipelinesWitness;
    }

    /**
     * Shortcut method for {@link PipelinesWitness#pipeline(String)}
     *
     * @param name The name of the pipeline witness to retrieve.
     * @return the associated {@link PipelineWitness} for the given name
     */
    public PipelineWitness pipeline(String name) {
        return pipelinesWitness.pipeline(name);
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        SERIALIZER.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson serializer.
     */
    static class Serializer extends StdSerializer<Witness> {

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(Witness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<Witness> t) {
            super(t);
        }

        @Override
        public void serialize(Witness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        void innerSerialize(Witness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            witness.events().genJson(gen, provider);
            witness.reloads().genJson(gen, provider);
            witness.pipelinesWitness.genJson(gen, provider);
        }
    }
}
