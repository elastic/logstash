package org.logstash.instruments.monitors;

import org.junit.Test;
import org.logstash.instrument.monitors.SystemMonitor;

import java.util.Map;

import static org.hamcrest.CoreMatchers.*;
import static org.hamcrest.MatcherAssert.assertThat;


public class SystemMonitorTest {

    @Test
    public void systemMonitorTest(){
        Map<String, Object> map = SystemMonitor.detect().toMap();
        assertThat("os.name is missing", map.get("os.name"), allOf(notNullValue(), instanceOf(String.class)));
        if (!((String) map.get("os.name")).startsWith("Windows")) {
            assertThat("system.load_average is missing", (Double) map.get("system.load_average") > 0, is(true));
        }
        assertThat("system.available_processors is missing ", ((Integer)map.get("system.available_processors")) > 0, is(true));
        assertThat("os.version is missing", map.get("os.version"), allOf(notNullValue(), instanceOf(String.class)));
        assertThat("os.arch is missing", map.get("os.arch"), allOf(notNullValue(), instanceOf(String.class)));
    }
}
