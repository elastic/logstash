package org.logstash.instrument.metrics;

import org.junit.Test;

import java.util.EnumSet;
import java.util.HashMap;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;


/**
 * Unit tests for {@link MetricType}
 */
public class MetricTypeTest {

    /**
     * The {@link String} version of the {@link MetricType} should be considered as a public contract, and thus non-passive to change. Admittedly this test is a bit silly since it
     * just duplicates the code, but should cause a developer to think twice if they are changing the public contract.
     */
    @Test
    public void ensurePassivity(){
        Map<MetricType, String>  nameMap = new HashMap(EnumSet.allOf(MetricType.class).size());
        nameMap.put(MetricType.COUNTER_LONG, "counter/long");
        nameMap.put(MetricType.GAUGE_TEXT, "gauge/text");
        nameMap.put(MetricType.GAUGE_BOOLEAN, "gauge/boolean");
        nameMap.put(MetricType.GAUGE_NUMERIC, "gauge/numeric");
        nameMap.put(MetricType.GAUGE_UNKNOWN, "gauge/unknown");
        nameMap.put(MetricType.GAUGE_RUBYHASH, "gauge/rubyhash");
        nameMap.put(MetricType.GAUGE_RUBYTIMESTAMP, "gauge/rubytimestamp");

        //ensure we are testing all of the enumerations
        assertThat(EnumSet.allOf(MetricType.class).size()).isEqualTo(nameMap.size());

        nameMap.forEach((k,v) -> assertThat(k.asString()).isEqualTo(v));
        nameMap.forEach((k,v) -> assertThat(MetricType.fromString(v)).isEqualTo(k));
    }

}