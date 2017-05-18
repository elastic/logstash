package org.logstash.instruments.monitors;


import org.junit.Test;
import org.logstash.instrument.monitors.HotThreadsMonitor;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

import static org.hamcrest.CoreMatchers.*;
import static org.hamcrest.MatcherAssert.assertThat;


public class HotThreadMonitorTest {

    @Test
    public void testThreadsReportsGenerated(){
        assertThat(new HotThreadsMonitor().detect().size() > 0, is(true));
    }

    @Test
    public void testAllThreadsHaveCpuTime(){
        new HotThreadsMonitor().detect().forEach(x -> assertThat(x.toMap().keySet(), hasItem("cpu.time")));
    }

    @Test
    public void testAllThreadsHaveThreadState(){
        new HotThreadsMonitor().detect().forEach(x -> assertThat(x.toMap().keySet(), hasItem("thread.state")));
    }

    @Test
    public void testAllThreadsHaveBlockedInformation(){
        new HotThreadsMonitor().detect().forEach(x -> assertThat(x.toMap().keySet(), hasItems("blocked.count", "blocked.time")));
    }

    @Test
    public void testAllThreadsHaveWaitedInformation(){
        new HotThreadsMonitor().detect().forEach(x -> assertThat(x.toMap().keySet(), hasItems("waited.count", "waited.time")));
    }

    @Test
    public void testAllThreadsHaveStackTraces(){
        new HotThreadsMonitor().detect().forEach(tr -> assertThat(tr.toMap().keySet(), hasItem("thread.stacktrace")));
    }

    @Test
    public void testStackTraceSizeOption(){
        final String testStackSize = "4";
        Map<String, String> options = new HashMap<>();
        options.put("stacktrace_size", testStackSize);
        new HotThreadsMonitor().detect(options).stream().filter(tr -> !tr.getThreadName().equals("Signal Dispatcher") &&
                                                                      !tr.getThreadName().equals("Reference Handler"))
                                                        .forEach(tr -> {
            List stackTrace = (List)tr.toMap().get("thread.stacktrace");
            assertThat(stackTrace.size(), is(Integer.valueOf(testStackSize)));
        });
    }

    @Test
    public void testOptionsOrderingCpu(){
        Map<String, String> options = new HashMap<>();
        options.put("ordered_by", "cpu");
        // Using single element array to circumvent lambda expectation of 'effective final'
        final long[] lastCpuTime = {Long.MAX_VALUE};
        new HotThreadsMonitor().detect(options).forEach(tr -> {
            Long cpuTime = (Long)tr.toMap().get("cpu.time");
            assertThat(lastCpuTime[0] >= cpuTime, is(true));
            lastCpuTime[0] = cpuTime;
        });
    }

    @Test
    public void testOptionsOrderingWait(){
        Map<String, String> options = new HashMap<>();
        options.put("ordered_by", "wait");
        // Using single element array to circumvent lambda expectation of 'effectively final'
        final long[] lastWaitTime = {Long.MAX_VALUE};
        new HotThreadsMonitor().detect(options).forEach(tr -> {
            Long waitTime = (Long)tr.toMap().get("waited.time");
            assertThat(lastWaitTime[0] >= waitTime, is(true));
            lastWaitTime[0] = waitTime;
        });
    }

    @Test
    public void testOptionsOrderingBlocked(){
        Map<String, String> options = new HashMap<>();
        options.put("ordered_by", "block");
        // Using single element array to circumvent lambda expectation of 'effectively final'
        final long[] lastBlockedTime = {Long.MAX_VALUE};
        new HotThreadsMonitor().detect(options).forEach(tr -> {
            Long blockedTime = (Long)tr.toMap().get("blocked.time");
            assertThat(lastBlockedTime[0] >= blockedTime, is(true));
            lastBlockedTime[0] = blockedTime;
        });
    }
}
