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

package org.logstash.instrument.metrics;

import co.elastic.logstash.api.UserMetric;
import org.HdrHistogram.Histogram;
import org.HdrHistogram.Recorder;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;

import java.time.Duration;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.concurrent.atomic.AtomicLong;
import java.util.function.LongSupplier;

public class HdrHistogramFlowMetric extends AbstractMetric<Map<String, HistogramMetricData>> implements HistogramFlowMetric {

    /**
     * Support class to hold a window of histogram snapshots and histogram recorder.
     * */
    private static final class HistogramSnapshotsWindow {
        private final FlowMetricRetentionPolicy retentionPolicy;
        private final LongSupplier nanoTimeSupplier;
        private final Recorder histogramRecorder;
        private final AtomicLong lastRecordTimeNanos;
        RetentionWindow recordWindow;
        final long estimatedSizeInBytes;

        HistogramSnapshotsWindow(FlowMetricRetentionPolicy retentionPolicy, LongSupplier nanoTimeSupplier) {
            this.retentionPolicy = retentionPolicy;
            this.nanoTimeSupplier = nanoTimeSupplier;
            this.histogramRecorder = new Recorder(1_000_000, 3);
            long actualTime = nanoTimeSupplier.getAsLong();
            lastRecordTimeNanos = new AtomicLong(actualTime);
            HistogramCapture initialCapture = new HistogramCapture(histogramRecorder.getIntervalHistogram(), actualTime);
            recordWindow = new RetentionWindow(retentionPolicy, initialCapture);
            estimatedSizeInBytes = initEstimatedSize();
        }

        private long initEstimatedSize() {
            Histogram snapshotHistogram = histogramRecorder.getIntervalHistogram();
            int estimatedFootprintInBytes = snapshotHistogram.getEstimatedFootprintInBytes();

            return recordWindow.policy.samplesCount() * estimatedFootprintInBytes;
        }

        void recordValue(long totalByteSize) {
            histogramRecorder.recordValue(totalByteSize);

            // Record on every call and create a snapshot iff we pass the flow metric policy resolution time
            long currentTimeNanos = nanoTimeSupplier.getAsLong();
            long updatedLast = lastRecordTimeNanos.accumulateAndGet(currentTimeNanos, (last, current) -> {
                if (current - last > retentionPolicy.resolutionNanos()) {
                    return current;
                } else {
                    return last;
                }
            });

            // If two threads race to update lastRecordTimeNanos, only one updates the variable. If two threads reads
            // currentTimeNanos that are different but really close to the other, then only one succeed in updating the atomic long,
            // and will satisfy updatedLast == currentTimeNanos, so will create the snapshot. The other will read a different
            // updatedLast and the condition will fail.
            // If two threads reads exactly the same nanosecond time, also in this case only one will update the atomic long, but both
            // will satisfy the condition and create two histogram snapshots, one of which will be probably empty.
            // In this case the recordWindow.append prefer the newest, so in case of two snapshots created at the same time,
            // the latter will be kept. Depending on the interleaving of the threads it could be that the empty one is kept.
            // Is this a problem? Probably not, because it concur to the calculation of the percentiles for a fraction, and
            // giving that's a statistical approximation, doesn't really matter having exact numbers.
            if (updatedLast == currentTimeNanos) {
                // an update of the lastRecordTimeNanos happened, we need to create a snapshot
                Histogram snapshotHistogram = histogramRecorder.getIntervalHistogram();
                LOG.debug("Capturing new histogram snapshot p50: {}, p90: {}",
                        snapshotHistogram.getValueAtPercentile(50), snapshotHistogram.getValueAtPercentile(90));
                recordWindow.append(new HistogramCapture(snapshotHistogram, currentTimeNanos));
            }
        }

        HistogramMetricData computeAggregatedHistogramData() {
            final Histogram windowAggregated = new Histogram(1_000_000, 3);
            final long currentTimeNanos = nanoTimeSupplier.getAsLong();
            recordWindow.forEachCapture(dpc -> {
                // When all captures fall outside of the retention window, the list still holds the last capture,
                // so have to check retention here again
                if ((currentTimeNanos - dpc.nanoTime()) > retentionPolicy.retentionNanos()) {
                    // skip captures outside of retention window
                    if (LOG.isTraceEnabled()) {
                        LOG.trace("Skipping capture outside of retention window {}, expired {} seconds ago",
                                retentionPolicy.policyName(),
                                Duration.ofNanos((currentTimeNanos - dpc.nanoTime()) - retentionPolicy.retentionNanos()).toSeconds());
                    }
                    return;
                }

                if (dpc instanceof HistogramCapture hdp) {
                    windowAggregated.add(hdp.getHdrHistogram());
                } else {
                    LOG.warn("Found {} which is not a HistogramCapture in HdrHistogramFlowMetric retention window",
                            dpc.getClass().getName());
                }
            });
            if (LOG.isTraceEnabled()) {
                LOG.trace("Captures held for policy {}, estimated size: {}", retentionPolicy, recordWindow.countCaptures());
            }
            return new HistogramMetricData(windowAggregated);
        }
    }

    private static final Logger LOG = LogManager.getLogger(HdrHistogramFlowMetric.class);

    public static UserMetric.Factory<HistogramFlowMetric> FACTORY = HistogramFlowMetric.PROVIDER.getFactory(HdrHistogramFlowMetric::new);

    private static final List<FlowMetricRetentionPolicy> SUPPORTED_POLICIES = List.of(
            FlowMetricRetentionPolicy.BuiltInRetentionPolicy.LAST_1_MINUTE,
            FlowMetricRetentionPolicy.BuiltInRetentionPolicy.LAST_5_MINUTES,
            FlowMetricRetentionPolicy.BuiltInRetentionPolicy.LAST_15_MINUTES
    );
    private final ConcurrentMap<FlowMetricRetentionPolicy, HistogramSnapshotsWindow> histogramsWindows = new ConcurrentHashMap<>();
    private final LongSupplier nanoTimeSupplier;

    /**
     * Constructor
     *
     * @param name The name of this metric. This value may be used for display purposes.
     */
    protected HdrHistogramFlowMetric(String name) {
        this(name, System::nanoTime);
    }

    // Used in tests
    protected HdrHistogramFlowMetric(String name, LongSupplier nanoTimeSupplier) {
        super(name);
        this.nanoTimeSupplier = nanoTimeSupplier;
        long totalEstimatedSize = 0L;
        for (FlowMetricRetentionPolicy policy : SUPPORTED_POLICIES) {
            HistogramSnapshotsWindow snapshotsWindow = new HistogramSnapshotsWindow(policy, nanoTimeSupplier);
            totalEstimatedSize += snapshotsWindow.estimatedSizeInBytes;
            histogramsWindows.put(policy, snapshotsWindow);
        }

        LOG.info("Estimated memory footprint for histogram metric is approximately {} bytes", totalEstimatedSize);
    }

    @Override
    public Map<String, HistogramMetricData> getValue() {
        final Map<String, HistogramMetricData> result = new HashMap<>();
        final long currentTimeNanos = nanoTimeSupplier.getAsLong();
        histogramsWindows.forEach((policy, window) -> {
            window.recordWindow.baseline(currentTimeNanos).ifPresent(baseline -> {
                result.put(policy.policyName().toLowerCase(), window.computeAggregatedHistogramData());
            });
        });
        return result;
    }

    @Override
    public void recordValue(long totalByteSize) {
        for (FlowMetricRetentionPolicy policy : SUPPORTED_POLICIES) {
            histogramsWindows.get(policy).recordValue(totalByteSize);
        }
    }
}
