package org.logstash.instrument.metrics.gauge;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.logstash.instrument.metrics.MetricType;
import org.mockito.runners.MockitoJUnitRunner;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link RubyTimeStampGauge}
 */
@SuppressWarnings("deprecation")
@RunWith(MockitoJUnitRunner.class)
public class RubyTimeStampGaugeTest {

    private static final Timestamp TIMESTAMP = new Timestamp();

    private static final JrubyTimestampExtLibrary.RubyTimestamp RUBY_TIMESTAMP =
        JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
            RubyUtil.RUBY, TIMESTAMP
        );

    @Test
    public void getValue() {
        RubyTimeStampGauge gauge = new RubyTimeStampGauge("bar", RUBY_TIMESTAMP);
        assertThat(gauge.getValue()).isEqualTo(RUBY_TIMESTAMP.getTimestamp());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);

        //Null initialize
        gauge = new RubyTimeStampGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);
    }

    @Test
    public void set() {
        RubyTimeStampGauge gauge = new RubyTimeStampGauge("bar");
        gauge.set(RUBY_TIMESTAMP);
        assertThat(gauge.getValue()).isEqualTo(RUBY_TIMESTAMP.getTimestamp());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);
    }
}
