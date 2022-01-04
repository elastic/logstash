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


package org.logstash.plugins.inputs;

import co.elastic.logstash.api.Configuration;
import co.elastic.logstash.api.Context;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.LogstashPlugin;
import co.elastic.logstash.api.PluginConfigSpec;
import co.elastic.logstash.api.PluginHelper;

import java.net.InetAddress;
import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.CountDownLatch;
import java.util.concurrent.Executors;
import java.util.concurrent.ScheduledExecutorService;
import java.util.concurrent.ScheduledFuture;
import java.util.concurrent.TimeUnit;
import java.util.function.Consumer;

/**
 * Java implementation of the "generator" input
 * */
@LogstashPlugin(name = "java_generator")
public class Generator implements Input {

    public static final PluginConfigSpec<Long> COUNT_CONFIG =
            PluginConfigSpec.numSetting("count", 0);
    public static final PluginConfigSpec<List<Object>> LINES_CONFIG =
            PluginConfigSpec.arraySetting("lines");
    public static final PluginConfigSpec<String> MESSAGE_CONFIG =
            PluginConfigSpec.stringSetting("message", "Hello world!");
    public static final PluginConfigSpec<Long> THREADS_CONFIG =
            PluginConfigSpec.numSetting("threads", 1);
    public static final PluginConfigSpec<Double> EPS_CONFIG =
            PluginConfigSpec.floatSetting("eps", 0);

    private final String hostname;
    private final long count;
    private final double eps;
    private String id;
    private long threads;
    private volatile boolean stopRequested = false;
    private final CountDownLatch countDownLatch;
    private String[] lines;
    private int[] linesIndex;
    private long[] sequence;
    private ScheduledFuture<?>[] futures;
    private List<Map<String, Object>> events;

    /**
     * Required constructor.
     *
     * @param id            Plugin id
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public Generator(final String id, final Configuration configuration, final Context context) {
        this.id = id;
        this.count = configuration.get(COUNT_CONFIG);
        this.eps = configuration.get(EPS_CONFIG);
        this.threads = configuration.get(THREADS_CONFIG);
        if (this.threads < 1) {
            throw new IllegalStateException("May not specify fewer than one generator thread");
        }
        this.countDownLatch = new CountDownLatch((int) threads);

        String host;
        try {
            host = InetAddress.getLocalHost().getHostName();
        } catch (UnknownHostException e) {
            host = "[unknownHost]";
        }
        this.hostname = host;

        // specifying "lines" will override "message"
        List<Object> linesConfig = configuration.get(LINES_CONFIG);
        if (linesConfig != null) {
            lines = new String[linesConfig.size()];
            for (int k = 0; k < linesConfig.size(); k++) {
                lines[k] = (String) linesConfig.get(k);
            }

        } else {
            lines = new String[]{configuration.get(MESSAGE_CONFIG)};
        }
    }

    @Override
    public void start(Consumer<Map<String, Object>> writer) {
        if (eps > 0) {
            startThrottledGenerator(writer);
        } else {
            startUnthrottledGenerator(writer);
        }
    }

    private void startUnthrottledGenerator(Consumer<Map<String, Object>> writer) {
        sequence = new long[(int) threads];
        events = new ArrayList<>();
        linesIndex = new int[(int) threads];

        for (int k = 0; k < threads; k++) {
            Map<String, Object> event = new HashMap<>();
            event.put("hostname", hostname);
            event.put("thread_number", k);
            events.add(event);
            if (k > 0) {
                final int finalK = k;
                Thread t = new Thread(() -> {
                    while (runGenerator(writer, finalK, () -> countDownLatch.countDown())) {
                    }
                });
                t.setName("generator_" + getId() + "_" + k);
                t.start();
            }
        }

        // run first generator on this thread
        while (runGenerator(writer, 0, () -> countDownLatch.countDown())) {}
    }

    private void startThrottledGenerator(Consumer<Map<String, Object>> writer) {
        ScheduledExecutorService ses = Executors.newScheduledThreadPool((int) threads);
        int delayMilli = (int) (1000.0 / eps);
        sequence = new long[(int) threads];
        futures = new ScheduledFuture<?>[(int) threads];
        events = new ArrayList<>();
        linesIndex = new int[(int) threads];
        for (int k = 0; k < threads; k++) {
            Map<String, Object> event = new HashMap<>();
            event.put("hostname", hostname);
            event.put("thread_number", k);
            events.add(event);
            final int finalk = k;
            futures[k] = ses.scheduleAtFixedRate(() -> runGenerator(writer, finalk, () -> {
                        countDownLatch.countDown();
                        futures[finalk].cancel(false);
                    }),0, delayMilli, TimeUnit.MILLISECONDS);
        }

        boolean finished = false;
        while (!stopRequested && !finished) {
            try {
                Thread.sleep(1000);
                boolean allCancelled = true;
                for (int k = 0; k < threads; k++) {
                    allCancelled = allCancelled && futures[k].isCancelled();
                }
                if (allCancelled) {
                    finished = true;
                    ses.shutdownNow();
                }
            } catch (InterruptedException ex) {
                // do nothing
            }
        }
    }

    private boolean runGenerator(Consumer<Map<String, Object>> writer, int thread, Runnable finishAction) {
        if (stopRequested || ((count > 0) && (sequence[thread] >= count))) {
            finishAction.run();
            return false;
        } else {
            events.get(thread).put("sequence", sequence[thread]);
            events.get(thread).put("message", lines[linesIndex[thread]++]);
            writer.accept(events.get(thread));
            if (linesIndex[thread] == lines.length) {
                linesIndex[thread] = 0;
                sequence[thread]++;
            }
            return true;
        }
    }

    @Override
    public void stop() {
        stopRequested = true;
    }

    @Override
    public void awaitStop() throws InterruptedException {
        countDownLatch.await();
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return PluginHelper.commonInputSettings(Arrays.asList(COUNT_CONFIG, LINES_CONFIG, MESSAGE_CONFIG,
                THREADS_CONFIG, EPS_CONFIG));
    }

    @Override
    public String getId() {
        return id;
    }
}
