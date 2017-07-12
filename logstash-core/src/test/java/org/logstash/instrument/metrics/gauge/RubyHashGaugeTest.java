package org.logstash.instrument.metrics.gauge;

import org.jruby.RubyHash;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.logstash.instrument.metrics.MetricType;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;
import static org.assertj.core.api.ThrowableAssert.catchThrowable;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link RubyHashGauge}
 */
@RunWith(MockitoJUnitRunner.class)
public class RubyHashGaugeTest {

    @Mock
    RubyHash rubyHash;

    private static final String RUBY_HASH_AS_STRING = "{}";

    @Before
    public void _setup() {
        //hacky workaround using the toString method to avoid mocking the Ruby runtime
        when(rubyHash.toString()).thenReturn(RUBY_HASH_AS_STRING);
    }

    @Test
    public void getValue() {
        RubyHashGauge gauge = new RubyHashGauge(Collections.singletonList("foo"), "bar", rubyHash);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);

        //Null initialize
        final RubyHashGauge gauge2 = new RubyHashGauge(Collections.singletonList("foo"), "bar");
        Throwable thrown = catchThrowable(() -> {
            gauge2.getValue().toString();
        });
        assertThat(thrown).isInstanceOf(NullPointerException.class);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);
    }

    @Test
    public void set() {
        RubyHashGauge gauge = new RubyHashGauge(Collections.singletonList("foo"), "bar");
        gauge.set(rubyHash);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);
    }

}