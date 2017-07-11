package org.logstash.instruments.monitors;

import org.junit.Test;
import org.logstash.instrument.monitors.MemoryMonitor;

import java.util.Map;

import static org.hamcrest.CoreMatchers.hasItem;
import static org.hamcrest.CoreMatchers.hasItems;
import static org.hamcrest.CoreMatchers.notNullValue;
import static org.hamcrest.MatcherAssert.assertThat;


public class MemoryMonitorTest {

    @Test
    public void testEachHeapSpaceRepresented() {
        Map<String, Map<String, Object>> heap = MemoryMonitor.detect(MemoryMonitor.Type.All).getHeap();
        assertThat(heap, notNullValue());
        assertThat(heap.keySet(), hasItems("PS Survivor Space", "PS Old Gen", "PS Eden Space"));
    }

    @Test
    public void testAllStatsAreAvailableForHeap(){
        testAllStatsAreAvailable(MemoryMonitor.detect(MemoryMonitor.Type.All).getHeap());
    }

    @Test
    public void testAllStatsAreAvailableForNonHeap(){
        testAllStatsAreAvailable(MemoryMonitor.detect(MemoryMonitor.Type.All).getNonHeap());
    }

    private void testAllStatsAreAvailable(Map<String, Map<String, Object>> stats){
        String[] types = {"usage", "peak"};
        String[] subtypes = {"used", "max", "committed", "init"};
        for (Map<String, Object> spaceMap: stats.values()){
            for (String type : types) {
                for (String subtype : subtypes){
                    String key = String.format("%s.%s", type, subtype);
                    assertThat(key + " is missing", spaceMap.keySet(), hasItem(key));
                }
            }
        }
    }
}
