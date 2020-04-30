/*
 * Licensed to Elasticsearch B.V. under one or more contributor
 * license agreements. See the NOTICE file distributed with
 * this work for additional information regarding copyright
 * ownership. Elasticsearch B.V. licenses this file to you under
 * the Apache License, Version 2.0 (the "License"); you may
 * not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *	http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing,
 * software distributed under the License is distributed on an
 * "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
 * KIND, either express or implied.  See the License for the
 * specific language governing permissions and limitations
 * under the License.
 */


package org.logstash.instruments.monitors;


import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.TimeUnit;
import org.junit.Test;
import org.logstash.instrument.monitors.HotThreadsMonitor;

import static org.hamcrest.CoreMatchers.hasItem;
import static org.hamcrest.CoreMatchers.hasItems;
import static org.hamcrest.CoreMatchers.is;
import static org.hamcrest.MatcherAssert.assertThat;


public class HotThreadMonitorTest {

    @Test
    public void testThreadsReportsGenerated(){
        assertThat(HotThreadsMonitor.detect().size() > 0, is(true));
    }

    @Test
    public void testAllThreadsHaveCpuTime(){
        HotThreadsMonitor.detect().forEach(x -> assertThat(x.toMap().keySet(), hasItem("cpu.time")));
    }

    @Test
    public void testAllThreadsHaveThreadState(){
        HotThreadsMonitor.detect().forEach(x -> assertThat(x.toMap().keySet(), hasItem("thread.state")));
    }

    @Test
    public void testAllThreadsHaveBlockedInformation(){
        HotThreadsMonitor.detect().forEach(x -> assertThat(x.toMap().keySet(), hasItems("blocked.count", "blocked.time")));
    }

    @Test
    public void testAllThreadsHaveWaitedInformation(){
        HotThreadsMonitor.detect().forEach(x -> assertThat(x.toMap().keySet(), hasItems("waited.count", "waited.time")));
    }

    @Test
    public void testAllThreadsHaveStackTraces(){
        HotThreadsMonitor.detect().forEach(tr -> assertThat(tr.toMap().keySet(), hasItem("thread.stacktrace")));
    }

    @Test
    public void testStackTraceSizeOption() throws InterruptedException {
        final String testStackSize = "4";
        final CountDownLatch latch = new CountDownLatch(1);
        final Thread thread = new Thread() {
            @Override
            public void run() {
                waitEnd();
            }

            void waitEnd() {
                try {
                    latch.await();
                } catch (final InterruptedException ex) {
                    throw new IllegalArgumentException(ex);
                }
            }
        };
        try {
            thread.start();
            TimeUnit.MILLISECONDS.sleep(300L);
            final Map<String, String> options = new HashMap<>();
            options.put("stacktrace_size", testStackSize);
            assertThat(
                ((List) HotThreadsMonitor.detect(options).stream()
                    .filter(tr -> thread.getName().equals(tr.getThreadName())).findFirst()
                    .get().toMap().get("thread.stacktrace")).size(),
                is(Integer.parseInt(testStackSize))
            );
        } finally {
            latch.countDown();
            thread.join();
        }
    }

    @Test
    public void testOptionsOrderingCpu(){
        Map<String, String> options = new HashMap<>();
        options.put("ordered_by", "cpu");
        // Using single element array to circumvent lambda expectation of 'effective final'
        final long[] lastCpuTime = {Long.MAX_VALUE};
        HotThreadsMonitor.detect(options).forEach(tr -> {
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
        HotThreadsMonitor.detect(options).forEach(tr -> {
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
        HotThreadsMonitor.detect(options).forEach(tr -> {
            Long blockedTime = (Long)tr.toMap().get("blocked.time");
            assertThat(lastBlockedTime[0] >= blockedTime, is(true));
            lastBlockedTime[0] = blockedTime;
        });
    }
}
