package org.logstash.instrument.metrics.gauge;

import java.net.URI;
import java.util.Collections;
import org.jruby.RubyHash;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.Timestamp;
import org.logstash.ext.JrubyTimestampExtLibrary;
import org.logstash.instrument.metrics.MetricType;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Unit tests for {@link LazyDelegatingGauge}
 */
public class LazyDelegatingGaugeTest {

    private static final RubyHash RUBY_HASH = RubyHash.newHash(RubyUtil.RUBY);

    private static final Timestamp TIMESTAMP = new Timestamp();

    private static final JrubyTimestampExtLibrary.RubyTimestamp RUBY_TIMESTAMP =
        JrubyTimestampExtLibrary.RubyTimestamp.newRubyTimestamp(
            RubyUtil.RUBY, TIMESTAMP
        );

    private static final String RUBY_HASH_AS_STRING = "{}";

    @Test
    public void getValue() {
        //Long
        LazyDelegatingGauge gauge = new LazyDelegatingGauge("bar", 99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);

        //Double
        gauge = new LazyDelegatingGauge("bar", 99.0);
        assertThat(gauge.getValue()).isEqualTo(99.0);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);

        //Boolean
        gauge = new LazyDelegatingGauge("bar", true);
        assertThat(gauge.getValue()).isEqualTo(true);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);

        //Text
        gauge = new LazyDelegatingGauge("bar", "something");
        assertThat(gauge.getValue()).isEqualTo("something");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);

        //Ruby Hash
        gauge = new LazyDelegatingGauge("bar", RUBY_HASH);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);

        //Ruby Timestamp
        gauge = new LazyDelegatingGauge("bar", RUBY_TIMESTAMP);
        assertThat(gauge.getValue()).isEqualTo(TIMESTAMP);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);

        //Unknown
        gauge = new LazyDelegatingGauge("bar", Collections.singleton("value"));
        assertThat(gauge.getValue()).isEqualTo(Collections.singleton("value"));
        assertThat(gauge.getValue()).isEqualTo(gauge.get());
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);

        //Null
        gauge = new LazyDelegatingGauge("bar");
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.get()).isNull();
        assertThat(gauge.getType()).isNull();
    }

    @Test
    public void set() {
        //Long
        LazyDelegatingGauge gauge = new LazyDelegatingGauge("bar");
        gauge.set(99l);
        assertThat(gauge.getValue()).isEqualTo(99l);
        gauge.set(199l);
        assertThat(gauge.getValue()).isEqualTo(199l);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);

        //Integer
        gauge = new LazyDelegatingGauge("bar");
        gauge.set(99);
        assertThat(gauge.getValue()).isEqualTo(99);
        gauge.set(199);
        assertThat(gauge.getValue()).isEqualTo(199);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);

        //Double
        gauge = new LazyDelegatingGauge("bar");
        gauge.set(99.0);
        assertThat(gauge.getValue()).isEqualTo(99.0);
        gauge.set(199.01);
        assertThat(gauge.getValue()).isEqualTo(199.01);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_NUMBER);

        //Boolean
        gauge = new LazyDelegatingGauge("bar");
        gauge.set(true);
        assertThat(gauge.getValue()).isEqualTo(true);
        gauge.set(false);
        assertThat(gauge.getValue()).isEqualTo(false);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_BOOLEAN);

        //Text
        gauge = new LazyDelegatingGauge("bar");
        gauge.set("something");
        assertThat(gauge.getValue()).isEqualTo("something");
        gauge.set("something else");
        assertThat(gauge.getValue()).isEqualTo("something else");
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);

        //Ruby Hash
        gauge = new LazyDelegatingGauge("bar");
        gauge.set(RUBY_HASH);
        assertThat(gauge.getValue().toString()).isEqualTo(RUBY_HASH_AS_STRING);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYHASH);

        //Ruby Timestamp
        gauge = new LazyDelegatingGauge("bar");
        gauge.set(RUBY_TIMESTAMP);
        assertThat(gauge.getValue()).isEqualTo(TIMESTAMP);
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_RUBYTIMESTAMP);

        //Unknown
        gauge = new LazyDelegatingGauge("bar");
        gauge.set(Collections.singleton("value"));
        assertThat(gauge.getValue()).isEqualTo(Collections.singleton("value"));
        gauge.set(URI.create("foo")); //please don't change the type of gauge after already set
        assertThat(gauge.getValue()).isEqualTo(URI.create("foo"));
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_UNKNOWN);

        //Null
        gauge = new LazyDelegatingGauge("bar");
        gauge.set(null);
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isNull();

        //Valid, then Null
        gauge = new LazyDelegatingGauge("bar");
        gauge.set("something");
        assertThat(gauge.getValue()).isEqualTo("something");
        gauge.set(null);
        assertThat(gauge.getValue()).isNull();
        assertThat(gauge.getType()).isEqualTo(MetricType.GAUGE_TEXT);
    }

}
