package org.logstash.instrument.witness.pipeline;


import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link ReloadWitness}
 */
@RunWith(MockitoJUnitRunner.class)
public class ReloadWitnessTest {

    private ReloadWitness witness;
    private Timestamp timestamp = new Timestamp();
    @Mock
    JrubyTimestampExtLibrary.RubyTimestamp rubyTimestamp;

    @Before
    public void setup() {
        witness = new ReloadWitness();
        when(rubyTimestamp.getTimestamp()).thenReturn(timestamp);
    }

    @Test
    public void testSuccess() {
        witness.success();
        witness.lastSuccessTimestamp(rubyTimestamp);
        assertThat(witness.snitch().successes()).isEqualTo(1);
        assertThat(witness.snitch().lastSuccessTimestamp()).isEqualTo(timestamp);
        witness.successes(99);
        assertThat(witness.snitch().successes()).isEqualTo(100);
    }

    @Test
    public void testFailure() {
        witness.failure();
        witness.lastFailureTimestamp(rubyTimestamp);
        assertThat(witness.snitch().failures()).isEqualTo(1);
        assertThat(witness.snitch().lastFailureTimestamp()).isEqualTo(timestamp);
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
        witness.lastSuccessTimestamp(rubyTimestamp);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"reloads\":{\"last_error\":{\"message\":null,\"backtrace\":null},\"successes\":1,\"last_success_timestamp\":\"" + timestamp.toIso8601() +
                "\",\"last_failure_timestamp\":null,\"failures\":0}}");
    }

    @Test
    public void testSerializeFailure() throws Exception {
        witness.failure();
        witness.lastFailureTimestamp(rubyTimestamp);
        String json = witness.asJson();
        assertThat(json).isEqualTo("{\"reloads\":{\"last_error\":{\"message\":null,\"backtrace\":null},\"successes\":0,\"last_success_timestamp\":null," +
                "\"last_failure_timestamp\":\"" + timestamp.toIso8601() + "\",\"failures\":1}}");
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
