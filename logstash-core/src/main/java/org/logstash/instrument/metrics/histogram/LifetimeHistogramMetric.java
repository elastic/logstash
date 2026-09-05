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

package org.logstash.instrument.metrics.histogram;

import co.elastic.logstash.api.UserMetric;
import org.HdrHistogram.PackedHistogram;
import org.logstash.instrument.metrics.AbstractMetric;
import org.HdrHistogram.Histogram;
import org.HdrHistogram.Recorder;

import java.util.Objects;

public class LifetimeHistogramMetric extends AbstractMetric<LifetimeHistogramMetric.ValueHistogram> implements HistogramMetric {

    private final Recorder recorder;
    private final Histogram lifetimeSnapshot;
    public static UserMetric.Factory<HistogramMetric> FACTORY =
            HistogramMetric.PROVIDER.getFactory(LifetimeHistogramMetric::new);

    public LifetimeHistogramMetric(String name) {
        super(name);
        //TODO recorder should be provided as a parameter constructor or lazy-initialized by a supplier, but this is sufficient for now
        this.recorder = new Recorder(3);
        this.lifetimeSnapshot = recorder.getIntervalHistogram();
    }

    @Override
    public void recordValue(long value) {
        if (value < 0) {
            throw new IllegalArgumentException("cannot record negative value in histogram");
        }
        recorder.recordValue(value);
    }

    @Override
    public int estimateBatchMetricsFootprintInBytes() {
        syncFromRecorder();
        // the recorder retains 1-2 internal histograms that are _potenially_ as big
        // as the lifetime snapshot we are accumulating.
        return 3 * this.lifetimeSnapshot.getEstimatedFootprintInBytes();
    }

    @Override
    public ValueHistogram getValue() {
        syncFromRecorder();
        return ValueHistogram.snapshotFrom(this.lifetimeSnapshot);
    }

    private synchronized void syncFromRecorder() {
        final Histogram uncommitted = recorder.getIntervalHistogram();
        if (uncommitted.getTotalCount() != 0) {
            this.lifetimeSnapshot.add(uncommitted);
        }
    }

    /**
     * A {@link ValueHistogram} is a read-only view of a histogram.
     */
    public static class ValueHistogram {
        private final PackedHistogram delegate;

        public static ValueHistogram snapshotFrom(Histogram value) {
            return new ValueHistogram(compactCopy(value));
        }

        private ValueHistogram(PackedHistogram delegate) {
            this.delegate = delegate;
        }

        public long getValueAtPercentile(double percentile) {
            return delegate.getValueAtPercentile(percentile);
        }

        public long getTotalCount() {
            return delegate.getTotalCount();
        }

        public long getMaxValue() {
            return delegate.getMaxValue();
        }

        public int getEstimatedFootprintInBytes() {
            // the cost of a pointer to the delegate plus the cost of the delegate itself
            return Long.BYTES + delegate.getEstimatedFootprintInBytes();
        }

        /**
         * @param other: an instance to compare
         * @return the difference between this histogram and the {@code other} histogram
         */
        public ValueHistogram subtract(ValueHistogram other) {
            if (Objects.isNull(other) || Objects.isNull(other.delegate) || other.delegate.getTotalCount() <= 0) {
                return this;
            }

            final PackedHistogram result = compactCopy(this.delegate);
            result.subtract(other.delegate);

            return new ValueHistogram(result);
        }

        /**
         * A "compact copy" has no concurrency primitives and therefore is NOT intended for updates outside
         * the scope in which it was created.
         *
         * @param source the source histogram
         * @return a copy that is just a `Histogram` without concurrency overhead.
         */
        private static PackedHistogram compactCopy(Histogram source) {
            final PackedHistogram result = new PackedHistogram(source); // infers structure, not data
            result.add(source);
            return result;
        }
    }
}
