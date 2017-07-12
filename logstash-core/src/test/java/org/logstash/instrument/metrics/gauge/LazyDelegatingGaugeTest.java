package org.logstash.instrument.metrics.gauge;

import org.jruby.RubyHash;
import org.junit.Before;
import org.junit.Test;
import org.junit.runner.RunWith;
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

    private static final String RUBY_HASH_AS_STRING = "{}";

    @Before
    public void _setup() {
        //hacky workaround using the toString method to avoid mocking the Ruby runtime
        when(rubyHash.toString()).thenReturn(RUBY_HASH_AS_STRING);
    }

    @Test
    public void getValue() {
        //Numeric
        LazyDelegatingGauge gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar", 99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);

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
        //Numeric
        LazyDelegatingGauge gauge = new LazyDelegatingGauge(Collections.singletonList("foo"), "bar");
        gauge.set(99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        gauge.set(199l);
        assertThat(gauge.getValue()).isEqualTo(199l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMERIC);

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