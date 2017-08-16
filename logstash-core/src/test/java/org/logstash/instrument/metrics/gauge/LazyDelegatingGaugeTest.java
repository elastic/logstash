package org.logstash.instrument.metrics.gauge;

import org.jruby.RubyHash;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.logstash.instrument.metrics.MetricType;
import org.mockito.Mock;
import org.mockito.runners.MockitoJUnitRunner;

import java.net.URI;
import java.util.Collections;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.Mockito.when;

/**
 * Unit tests for {@link LazyDelegatingGauge}
 */
@RunWith(MockitoJUnitRunner.class)
public class LazyDelegatingGaugeTest {

    @Mock
    RubyHash rubyHash;

    @Mock
    private JrubyTimestampExtLibrary.RubyTimestamp rubyTimestamp;

    private final Timestamp timestamp = new Timestamp();

    private static final String RUBY_HASH_AS_STRING = "{}";

    @Before
    public void _setup() {
        //hacky workaround using the toString method to avoid mocking the Ruby runtime
        when(rubyHash.toString()).thenReturn(RUBY_HASH_AS_STRING);
        when(rubyTimestamp.getTimestamp()).thenReturn(timestamp);
    }

    @Test
    public void getValue() {
        //Long
        LazyDelegatingGauge gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", 99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LONG);

        //Double
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", 99.0);
        assertThat(gauge.getValue()).isEqualTo(99.0);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_DOUBLE);

        //Boolean
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", true);
        assertThat(gauge.getValue()).isEqualTo(true);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);

        //Text
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", "something");
        assertThat(gauge.getValue()).isEqualTo("something");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);

        //Ruby Hash
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", rubyHash);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);

        //Ruby Timestamp
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", rubyTimestamp);
        assertThat(gauge.getValue()).isEqualTo(timestamp);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);

        //Unknown
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", Collections.singleton("value"));
        assertThat(gauge.getValue()).isEqualTo(Collections.singleton("value"));
        assertThat(gauge.getValue()).isEqualTo(gauge.get());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);

        //Null
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.get()).isNull();
        assertThat(gauge.getType()).isNull();
    }

    @Test
    public void set() {
        //Long
        LazyDelegatingGauge gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        gauge.set(199l);
        assertThat(gauge.getValue()).isEqualTo(199l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_LONG);

        //Double
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(99.0);
        assertThat(gauge.getValue()).isEqualTo(99.0);
        gauge.set(199.01);
        assertThat(gauge.getValue()).isEqualTo(199.01);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_DOUBLE);

        //Boolean
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(true);
        assertThat(gauge.getValue()).isEqualTo(true);
        gauge.set(false);
        assertThat(gauge.getValue()).isEqualTo(false);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);

        //Text
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set("something");
        assertThat(gauge.getValue()).isEqualTo("something");
        gauge.set("something else");
        assertThat(gauge.getValue()).isEqualTo("something else");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);

        //Ruby Hash
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(rubyHash);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);

        //Ruby Timestamp
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(rubyTimestamp);
        assertThat(gauge.getValue()).isEqualTo(timestamp);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);

        //Unknown
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(Collections.singleton("value"));
        assertThat(gauge.getValue()).isEqualTo(Collections.singleton("value"));
        gauge.set(URI.create("foo")); //please don't change the type of gauge after already set
        assertThat(gauge.getValue()).isEqualTo(URI.create("foo"));
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);

        //Null
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(null);
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isNull();

        //Valid, then Null
        gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set("something");
        assertThat(gauge.getValue()).isEqualTo("something");
        gauge.set(null);
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);
    }

}