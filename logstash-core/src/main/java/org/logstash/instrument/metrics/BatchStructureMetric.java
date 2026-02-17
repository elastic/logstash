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

import com.fasterxml.jackson.annotation.JsonProperty;

import org.HdrHistogram.Histogram;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.instrument.metrics.histogram.HistogramMetric;

import java.io.Serial;
import java.io.Serializable;
import java.util.Collections;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Optional;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ConcurrentMap;
import java.util.function.LongSupplier;

public class BatchStructureMetric extends AbstractMetric<Map<String, BatchStructureMetric.HistogramMetricData>>{
    private static final Logger LOG = LogManager.getLogger(BatchStructureMetric.class);

    private final HistogramMetric batchHistogram;
    private final LongSupplier nanoTimeSupplier;

    private static final List<FlowMetricRetentionPolicy> SUPPORTED_POLICIES = List.of(
            BuiltInFlowMetricRetentionPolicies.LAST_1_MINUTE,
            BuiltInFlowMetricRetentionPolicies.LAST_5_MINUTES,
            BuiltInFlowMetricRetentionPolicies.LAST_15_MINUTES
    );
    private final ConcurrentMap<FlowMetricRetentionPolicy, HistogramRetentionWindow> histogramsWindows = new ConcurrentHashMap<>();

    public BatchStructureMetric(final String name, final HistogramMetric batchHistogram) {
        this(name, batchHistogram, System::nanoTime);
    }

    public BatchStructureMetric(final String name,
                                final HistogramMetric batchHistogram,
                                final LongSupplier nanoTimeSupplier) {
        super(name);
        this.batchHistogram = batchHistogram;
        this.nanoTimeSupplier = nanoTimeSupplier;
    }

    public void capture() {
        HistogramCapture histogramCapture = new HistogramCapture(batchHistogram.getValue(), nanoTimeSupplier.getAsLong());
        LOG.trace("Captured batch structure metric: {}", histogramCapture);

        for (FlowMetricRetentionPolicy retentionPolicy : SUPPORTED_POLICIES) {
            appendToPolicyRetentionWindow(retentionPolicy, histogramCapture);
        }
    }

    private void appendToPolicyRetentionWindow(final FlowMetricRetentionPolicy retentionPolicy,
                                               final HistogramCapture histogramCapture) {
        histogramsWindows
                .computeIfAbsent(retentionPolicy, policy -> new HistogramRetentionWindow(policy, histogramCapture))
                .append(histogramCapture);
    }

    @Override
    public MetricType getType() {
        return MetricType.USER;
    }

    @Override
    public Map<String, HistogramMetricData> getValue() {
        capture();

        final Map<String, HistogramMetricData> rates = new LinkedHashMap<>();
        for (Map.Entry<FlowMetricRetentionPolicy, HistogramRetentionWindow> entry : histogramsWindows.entrySet()) {
            FlowMetricRetentionPolicy retentionPolicy = entry.getKey();
            HistogramRetentionWindow retentionWindow = entry.getValue();
            if (retentionWindow == null) {
                continue;
            }

            retentionWindow.calculateValue()
                    .ifPresent(histogram -> rates.put(retentionPolicy.policyName(), new HistogramMetricData(histogram)));
        }

        return Collections.unmodifiableMap(rates);
    }

    /**
     * Presentation class to render histogram data, leverage it's JSON serializability.
     * */
    public static class HistogramMetricData implements Serializable {
        @Serial
        private static final long serialVersionUID = 4711735381843512566L;
        private final long percentile50;
        private final long percentile90;

        public HistogramMetricData(Histogram hdrHistogram) {
            percentile50 = hdrHistogram.getValueAtPercentile(50);
            percentile90 = hdrHistogram.getValueAtPercentile(90);
        }

        @JsonProperty("p50")
        public double get50Percentile() {
            return percentile50;
        }

        @JsonProperty("p90")
        public double get90Percentile() {
            return percentile90;
        }

        @Override
        public String toString() {
            return "HistogramMetricData{" +
                    "percentile50=" + percentile50 +
                    ", percentile90=" + percentile90 +
                    '}';
        }
    }

    static class HistogramRetentionWindow extends RetentionWindow<HistogramCapture, Histogram> {

        private static final Comparator<HistogramCapture> HISTOGRAM_CAPTURE_COMPARATOR =
                Comparator.comparingLong(HistogramCapture::nanoTime);

        HistogramRetentionWindow(FlowMetricRetentionPolicy policy, HistogramCapture zeroCapture) {
            super(policy, zeroCapture);
        }

        @Override
        HistogramCapture mergeCaptures(HistogramCapture oldCapture, HistogramCapture newCapture) {
            if (oldCapture == null) {
                return newCapture;
            }
            if (newCapture == null) {
                return oldCapture;
            }

            // select newest capture because histogram is incremental and newer capture will have all the data of the
            // older one plus any new data since then, so no need to merge histograms
            return HISTOGRAM_CAPTURE_COMPARATOR.compare(oldCapture, newCapture) <= 0 ? newCapture : oldCapture;
        }

        @Override
        Optional<Histogram> calculateValue() {
            return calculateFromBaseline((compareCapture, baselineCapture) -> {
                if (compareCapture == null) { return Optional.empty(); }
                if (baselineCapture == null) { return Optional.empty(); }

                var result = compareCapture.getHdrHistogram().copy();
                result.subtract(baselineCapture.getHdrHistogram());
                return Optional.of(result);
            });
        }
    }
}
