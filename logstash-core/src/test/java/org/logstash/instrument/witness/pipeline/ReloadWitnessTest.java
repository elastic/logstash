package org.logstash.instrument.witness.pipeline;


import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link ReloadWitness}
 */
public class ReloadWitnessTest {

    private ReloadWitness witness;

    private static final Timestamp TIMESTAMP = new Timestamp();

    private static final JrubyTimestampExtLibrary.RubyTimestamp RUBY_TIMESTAMP =
        JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
            RubyUtil.RUBY, TIMESTAMP
        );

    @Before
    public void setup() {
        witness = new ReloadWitness();
    }

    @Test
    public void testSuccess() {
        witness.success();
        witness.lastSuccessTimestamp(RUBY_TIMESTAMP);
        assertThat(witness.snitch().successes()).isEqualTo(1);
        assertThat(witness.snitch().lastSuccessTimestamp()).isEqualTo(TIMESTAMP);
        witness.successes(99);
        assertThat(witness.snitch().successes()).isEqualTo(100);
    }

    @Test
    public void testFailure() {
        witness.failure();
        witness.lastFailureTimestamp(RUBY_TIMESTAMP);
        assertThat(witness.snitch().failures()).isEqualTo(1);
        assertThat(witness.snitch().lastFailureTimestamp()).isEqualTo(TIMESTAMP);
        witness.failures(99);
        assertThat(witness.snitch().failures()).isEqualTo(100);
    }

    @Test
    public void testError() {
        witness.error().message("foo");
        assertThat(witness.error().snitch().message()).isEqualTo("foo");
    }

    @Test
    public void testAsJson() throws Exception {
        ObjectMapper mapper = new ObjectMapper();
        assertThat(mapper.writeValueAsString(witness)).isEqualTo(witness.asJson());
    }

    @Test
    public void testSerializeEmpty() throws Exception {
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"reloads\":{\"last_error\":{\"message\":null,\"backtrace\":null},\"successes\":0,\"last_success_timestamp\":null," +
                "\"last_failure_timestamp\":null,\"failures\":0}}");
    }

    @Test
    public void testSerializeSuccess() throws Exception {
        witness.success();
        witness.lastSuccessTimestamp(RUBY_TIMESTAMP);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"reloads\":{\"last_error\":{\"message\":null,\"backtrace\":null},\"successes\":1,\"last_success_timestamp\":\"" 
            + TIMESTAMP.toString() + "\",\"last_failure_timestamp\":null,\"failures\":0}}");
    }

    @Test
    public void testSerializeFailure() throws Exception {
        witness.failure();
        witness.lastFailureTimestamp(RUBY_TIMESTAMP);
        String json = witness.asJson();
        assertThat(json).isEqualTo(
            "{\"reloads\":{\"last_error\":{\"message\":null,\"backtrace\":null},\"successes\":0,\"last_success_timestamp\":null," +
                "\"last_failure_timestamp\":\"" + TIMESTAMP.toString() + "\",\"failures\":1}}"
        );
    }

    @Test
    public void testSerializeError() throws Exception{
        witness.error().message("foo");
        witness.error().backtrace("bar");
        String json = witness.asJson();
        assertThat(json).contains("foo");
        assertThat(json).contains("bar");
    }

}
