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

import java.time.Duration;

interface FlowMetricRetentionPolicy {

    String policyName();

    boolean reportBeforeSatisfied();

    long retentionBarrierNanos(final long referenceNanos);

    long forceCompactionBarrierNanos(final long referenceNanos);

    long commitBarrierNanos(final long referenceNanos);

    long maxAgeBarrierNanos(final long referenceNanos);

    class RollingRetentionPolicy implements FlowMetricRetentionPolicy {

        final long resolutionNanos;
        final long retentionNanos;

        final long forceCompactionNanos;

        final boolean reportBeforeSatisfied;

        final transient String nameLower;

        RollingRetentionPolicy(final String name,
                               final Duration maximumRetention,
                               final Duration minimumResolution,
                               final boolean reportBeforeSatisfied) {
            this.retentionNanos = maximumRetention.toNanos();
            this.resolutionNanos = minimumResolution.toNanos();
            this.reportBeforeSatisfied = reportBeforeSatisfied;

            // we generally rely on query-time compaction, and only perform insertion-time compaction
            // if our series' head entry is significantly older than our maximum retention, which
            // allows us to ensure a reasonable upper-bound of collection size without incurring the
            // cost of compaction too often or inspecting the collection's size.
            final long forceCompactionMargin = Math.max(Duration.ofSeconds(30).toNanos(),
                                                        Math.multiplyExact(resolutionNanos, 8));
            this.forceCompactionNanos = Math.addExact(retentionNanos, forceCompactionMargin);

            this.nameLower = name.toLowerCase();
        }

        RollingRetentionPolicy(final String name,
                               final Duration maximumRetention,
                               final Duration minimumResolution) {
            this(name, maximumRetention, minimumResolution, false);
        }

        @Override
        public String policyName() {
            return nameLower;
        }

        @Override
        public long retentionBarrierNanos(final long referenceNanos) {
            return Math.subtractExact(referenceNanos, retentionNanos);
        }

        @Override
        public long forceCompactionBarrierNanos(final long referenceNanos) {
            return Math.subtractExact(referenceNanos, forceCompactionNanos);
        }

        @Override
        public long commitBarrierNanos(final long referenceNanos) {
            return Math.subtractExact(referenceNanos, resolutionNanos);
        }

        @Override
        public long maxAgeBarrierNanos(final long referenceNanos) {
            final long maxAge = Math.addExact(retentionNanos, resolutionNanos);
            return Math.subtractExact(referenceNanos, maxAge);
        }

        @Override
        public boolean reportBeforeSatisfied() {
            return this.reportBeforeSatisfied;
        }
    }
}
