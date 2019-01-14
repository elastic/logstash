package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.witness.pipeline.EventsWitness;
import org.logstash.instrument.witness.pipeline.PipelineWitness;
import org.logstash.instrument.witness.pipeline.PipelinesWitness;
import org.logstash.instrument.witness.pipeline.ReloadWitness;
import org.logstash.instrument.witness.process.ProcessWitness;
import org.logstash.instrument.witness.schedule.WitnessScheduler;

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
public final class Witness implements SerializableWitness {

    private final ReloadWitness reloadWitness;
    private final EventsWitness eventsWitness;
    private final PipelinesWitness pipelinesWitness;
    private final ProcessWitness processWitness;
    private final WitnessScheduler processWitnessScheduler;

    private static Witness instance;

    /**
     * Constructor. Consumers should use {@link #instance()} method to obtain an instance of this class.
     * <p>THIS IS ONLY TO BE USED BY THE RUBY AGENT</p>
     */
    public Witness() {
        this.reloadWitness = new ReloadWitness();
        this.eventsWitness = new EventsWitness();
        this.pipelinesWitness = new PipelinesWitness();
        this.processWitness = new ProcessWitness();
        this.processWitnessScheduler = new WitnessScheduler(processWitness);
    }

    /**
     * This is a dirty hack since the {@link Witness} needs to mirror the Ruby agent's lifecycle which, at least for testing, can mean more then 1 instance per JVM, but only 1
     * active instance at any time.  Exposing this allows Ruby to create the instance for use in it's agent constructor, then set it here for all to use as a singleton.
     * <p>THIS IS ONLY TO BE USED BY THE RUBY AGENT</p>
     *
     * @param newInstance The instance of the {@link Witness} to use as the singleton instance that mirror's the agent's lifecycle.
     */
    public static synchronized void setInstance(Witness newInstance) {
        //Ruby agent restart
        if (instance != null) {
            instance.processWitnessScheduler.shutdown();
        }

        instance = newInstance;

        if (instance != null) {
            instance.processWitnessScheduler.schedule();
        }
    }

    /**
     * Obtain the singleton instance of the {@link Witness}
     *
     * @return the singleton instance of the {@link Witness}
     * @throws IllegalStateException if attempted to be used before being set.
     */
    public static Witness instance() {
        if (instance == null) {
            throw new IllegalStateException("The stats witness instance must be set before it used. Called from: " + Arrays.toString(new Throwable().getStackTrace()));
        }
        return instance;
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
     * Obtain a reference to the associated process witness.
     *
     * @return The associated {@link ProcessWitness}
     */
    public ProcessWitness process() {
        return processWitness;
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
        Serializer.innerSerialize(this, gen, provider);
    }

    /**
     * The Jackson serializer.
     */
    public static final class Serializer extends StdSerializer<Witness> {

        private static final long serialVersionUID = 1L;

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
        private Serializer(Class<Witness> t) {
            super(t);
        }

        @Override
        public void serialize(Witness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen, provider);
            gen.writeEndObject();
        }

        static void innerSerialize(Witness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            witness.process().genJson(gen, provider);
            witness.events().genJson(gen, provider);
            witness.reloads().genJson(gen, provider);
            witness.pipelinesWitness.genJson(gen, provider);
        }
    }
}
