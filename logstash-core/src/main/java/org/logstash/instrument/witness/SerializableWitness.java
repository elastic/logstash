package org.logstash.instrument.witness;

import com.fasterxml.jackson.core.JsonFactory;
import com.fasterxml.jackson.core.JsonGenerator;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializerProvider;

import java.io.IOException;
import java.io.StringWriter;

/**
 * A Witness that can be serialized as JSON. A Witness is an abstraction to the {@link org.logstash.instrument.metrics.Metric}'s that watches/witnesses what is happening inside
 * of Logstash.
 */
public interface SerializableWitness {

    /**
     * Generates the corresponding JSON for the witness.
     *
     * @param gen      The {@link JsonGenerator} used to generate the JSON
     * @param provider The {@link SerializerProvider} that may be used to assist with the JSON generation.
     * @throws IOException if any errors occur in JSON generation
     */
    void genJson(final JsonGenerator gen, SerializerProvider provider) throws IOException;

    /**
     * Helper method to return the Witness as a JSON string.
     *
     * @return A {@link String} whose content is the JSON representation for the witness.
     * @throws IOException if any errors occur in JSON generation
     */
    default String asJson() throws IOException {
        JsonFactory jsonFactory = new JsonFactory();
        try (StringWriter sw = new StringWriter();
             JsonGenerator gen = jsonFactory.createGenerator(sw)) {
            ObjectMapper mapper = new ObjectMapper(jsonFactory);
            gen.writeStartObject();
            genJson(gen, mapper.getSerializerProvider());
            gen.writeEndObject();
            gen.flush();
            sw.flush();
            return sw.toString();
        }
    }
}
