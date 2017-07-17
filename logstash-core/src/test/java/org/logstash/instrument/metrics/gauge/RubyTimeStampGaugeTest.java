package org.logstash.instrument.metrics.gauge;

import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary.RubyTimestamp;
import org.logstash.instrument.metrics.MetricType;
import org.mockito.Mock;
import org.mockito.Mockito;
import org.mockito.runners.MockitoJUnitRunner;

import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link RubyTimeStampGauge}
 */
@RunWith(MockitoJUnitRunner.class)
public class RubyTimeStampGaugeTest {

    @Mock
    private RubyTimestamp rubyTimestamp;

    private final Timestamp timestamp = new Timestamp();

    @Before
    public void _setup() {
        when(rubyTimestamp.getTimestamp()).thenReturn(timestamp);
    }

    @Test
    public void getValue() {
        RubyTimeStampGauge gauge = new RubyTimeStampGauge(Collections.singletonList("foo"), "bar", rubyTimestamp);
        assertThat(gauge.getValue()).isEqualTo(rubyTimestamp.getTimestamp());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);

        //Null initialize
        gauge = new RubyTimeStampGauge(Collections.singletonList("foo"), "bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);
    }

    @Test
    public void set() {
        RubyTimeStampGauge gauge = new RubyTimeStampGauge(Collections.singletonList("foo"), "bar", Mockito.mock(RubyTimestamp.class));
        gauge.set(rubyTimestamp);
        assertThat(gauge.getValue()).isEqualTo(rubyTimestamp.getTimestamp());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);
    }
}