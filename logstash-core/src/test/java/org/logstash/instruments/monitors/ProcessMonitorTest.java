package org.logstash.instruments.monitors;

import org.junit.Test;
import org.logstash.instrument.monitors.ProcessMonitor;

import java.util.Map;

import static org.hamcrest.CoreMatchers.instanceOf;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;
import static org.junit.Assume.assumeTrue;

public class ProcessMonitorTest {


    @Test
    public void testReportFDStats(){
        Map<String, Object> processStats = ProcessMonitor.detect().toMap();
        assumeTrue((Boolean) processStats.get("is_unix"));
        assertThat("open_file_descriptors", (Long)processStats.get("open_file_descriptors") > 0L, is(true));
        assertThat("max_file_descriptors", (Long)processStats.get("max_file_descriptors") > 0L, is(true));
    }

    @Test
    public void testReportCpuStats(){
        Map<String, Object> processStats = ProcessMonitor.detect().toMap();
        assumeTrue((Boolean) processStats.get("is_unix"));
        assertThat("cpu", processStats.get("cpu"), instanceOf(Map.class));
        Map cpuStats = ((Map)processStats.get("cpu"));
        assertThat("cpu.process_percent", (Short)cpuStats.get("process_percent") >= 0, is(true));
        assertThat("cpu.system_percent", (Short)cpuStats.get("system_percent") >= -1, is(true));
        assertThat("cpu.total_in_millis", (Long)cpuStats.get("total_in_millis") > 0L, is(true));
    }

    @Test
    public void testReportMemStats() {
        Map<String, Object> processStats = ProcessMonitor.detect().toMap();
        assumeTrue((Boolean) processStats.get("is_unix"));
        assertThat("mem", processStats.get("mem"), instanceOf(Map.class));
        Map memStats = ((Map)processStats.get("mem"));
        assertThat("mem.total_virtual_in_bytes", (Long)memStats.get("total_virtual_in_bytes") >= 0L, is(true));
    }
}
