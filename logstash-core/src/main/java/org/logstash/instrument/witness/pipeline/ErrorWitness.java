package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.SerializerProvider;
import com.fasterxml.jackson.databind.annotation.JsonSerialize;
import com.fasterxml.jackson.databind.ser.std.StdSerializer;
import org.logstash.instrument.metrics.Metric;
import org.logstash.instrument.metrics.gauge.TextGauge;
import org.logstash.instrument.witness.MetricSerializer;
import org.logstash.instrument.witness.SerializableWitness;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.io.PrintStream;

/**
 * Witness for errors.
 */
@JsonSerialize(using = ErrorWitness.Serializer.class)
public class ErrorWitness implements SerializableWitness {

    private final TextGauge message;
    private final TextGauge backtrace;
    private final Snitch snitch;
    private static final String KEY = "last_error";

    public ErrorWitness() {
        message = new TextGauge("message");
        backtrace = new TextGauge("backtrace");
        snitch = new Snitch(this);
    }

    /**
     * Stacktrace as a {@link String}
     *
     * @param stackTrace The stack trace already formatted for output.
     */
    public void backtrace(String stackTrace) {
        this.backtrace.set(stackTrace);
    }

    /**
     * The message of the error.
     *
     * @param message human readable error message.
     */
    public void message(String message) {
        this.message.set(message);
    }

    /**
     * Get a reference to associated snitch to get discrete metric values.
     *
     * @return the associate {@link Snitch}
     */
    public Snitch snitch() {
        return this.snitch;
    }

    /**
     * Stacktrace for Java.
     *
     * @param throwable The Java {@link Throwable} that contains the stacktrace to output
     */
    public void backtrace(Throwable throwable) {

        try (ByteArrayOutputStream byteArrayOutputStream = new ByteArrayOutputStream();
             PrintStream printStream = new PrintStream(byteArrayOutputStream)) {

            throwable.printStackTrace(printStream);
            String backtrace = byteArrayOutputStream.toString("UTF-8");
            this.backtrace.set(backtrace);

        } catch (IOException e) {
            //A checked exception due to a the close on a ByteArrayOutputStream is simply annoying since it is an empty method.  This will never be called.
            throw new IllegalStateException("Unknown error", e);
        }
    }

    @Override
    public void genJson(JsonGenerator gen, SerializerProvider provider) throws IOException {
        Serializer.innerSerialize(this, gen);
    }

    /**
     * The Jackson serializer.
     */
    public static final class Serializer extends StdSerializer<ErrorWitness> {

        private static final long serialVersionUID = 1L;

        /**
         * Default constructor - required for Jackson
         */
        public Serializer() {
            this(ErrorWitness.class);
        }

        /**
         * Constructor
         *
         * @param t the type to serialize
         */
        protected Serializer(Class<ErrorWitness> t) {
            super(t);
        }

        @Override
        public void serialize(ErrorWitness witness, JsonGenerator gen, SerializerProvider provider) throws IOException {
            gen.writeStartObject();
            innerSerialize(witness, gen);
            gen.writeEndObject();
        }

        static void innerSerialize(ErrorWitness witness, JsonGenerator gen) throws IOException {
            gen.writeObjectFieldStart(KEY);
            MetricSerializer<Metric<String>> stringSerializer = MetricSerializer.Get.stringSerializer(gen);
            stringSerializer.serialize(witness.message);
            stringSerializer.serialize(witness.backtrace);
            gen.writeEndObject();
        }
    }

    /**
     * The snitch for the errors. Used to retrieve discrete metric values.
     */
    public static final class Snitch {
        private final ErrorWitness witness;

        private Snitch(ErrorWitness witness) {
            this.witness = witness;
        }

        /**
         * Gets the error message
         *
         * @return the error message. May be {@code null}
         */
        public String message() {
            return witness.message.getValue();
        }

        /**
         * Gets the error stack/back trace
         *
         * @return the backtrace as a String. May be {@code null}
         */
        public String backtrace() {
            return witness.backtrace.getValue();
        }
    }
}
