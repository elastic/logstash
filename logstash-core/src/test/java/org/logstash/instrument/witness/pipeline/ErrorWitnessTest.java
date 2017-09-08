package org.logstash.instrument.witness.pipeline;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link ErrorWitness}
 */
public class ErrorWitnessTest {

    private ErrorWitness witness;

    @Before
    public void setup() {
        witness = new ErrorWitness();
    }

    @Test
    public void backtrace() {
        //as String
        witness.backtrace("foo");
        assertThat(witness.snitch().backtrace()).isEqualTo("foo");

        //as Exception
        RuntimeException exception = new RuntimeException("foobar");
        witness.backtrace(exception);
        for (StackTraceElement element : exception.getStackTrace()) {
            assertThat(witness.snitch().backtrace()).contains(element.toString());
        }
    }

    @Test
    public void message() {
        witness.message("baz");
        assertThat(witness.snitch().message()).isEqualTo("baz");
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson()).contains("last_error");
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"last_error\":{\"message\":null,\"backtrace\":null}}");
    }

    @Test
    public void testSerializeMessage() throws Exception {
        witness.message("whoops");
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"last_error\":{\"message\":\"whoops\",\"backtrace\":null}}");
    }

    @Test
    public void testSerializeBackTrace() throws Exception {
        witness.backtrace("ruby, backtrace");
        String json = witness.asJson();
        assertThat(json).contains("ruby").contains("backtrace");

        witness.backtrace(new RuntimeException("Uh oh!"));
        json = witness.asJson();
        assertThat(json).contains("Uh oh!").contains("ErrorWitnessTest");
    }
}
