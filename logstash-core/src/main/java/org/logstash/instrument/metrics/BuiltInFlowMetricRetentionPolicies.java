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

import org.logstash.instrument.metrics.FlowMetricRetentionPolicy.RollingRetentionPolicy;

import java.time.Duration;
import java.util.Collections;
import java.util.LinkedHashSet;
import java.util.Set;

class BuiltInFlowMetricRetentionPolicies {

    private BuiltInFlowMetricRetentionPolicies() {
    }

    static final FlowMetricRetentionPolicy CURRENT = new RollingRetentionPolicy("current", Duration.ofSeconds(10), Duration.ofSeconds(1), true);

    static final FlowMetricRetentionPolicy LAST_1_MINUTE = new RollingRetentionPolicy("last_1_minute", Duration.ofMinutes(1), Duration.ofSeconds(3));

    static final FlowMetricRetentionPolicy LAST_5_MINUTES = new RollingRetentionPolicy("last_5_minutes", Duration.ofMinutes(5), Duration.ofSeconds(15));

    static final FlowMetricRetentionPolicy LAST_15_MINUTES = new RollingRetentionPolicy("last_15_minutes", Duration.ofMinutes(15), Duration.ofSeconds(30));

    static final FlowMetricRetentionPolicy LAST_1_HOUR = new RollingRetentionPolicy("last_1_hour", Duration.ofHours(1), Duration.ofMinutes(1));

    static final FlowMetricRetentionPolicy LAST_24_HOURS = new RollingRetentionPolicy("last_24_hours", Duration.ofHours(24), Duration.ofMinutes(15));

    static final FlowMetricRetentionPolicy LIFETIME = new FlowMetricRetentionPolicy() {
        @Override
        public String policyName() {
            return "lifetime";
        }

        @Override
        public boolean reportBeforeSatisfied() {
            return true;
        }

        @Override
        public long retentionBarrierNanos(long referenceNanos) {
            return Long.MIN_VALUE;
        }

        @Override
        public long forceCompactionBarrierNanos(long referenceNanos) {
            return Long.MIN_VALUE;
        }

        @Override
        public long commitBarrierNanos(long referenceNanos) {
            return Long.MIN_VALUE;
        }

        @Override
        public long maxAgeBarrierNanos(long referenceNanos) {
            return Long.MIN_VALUE;
        }
    };

    private static final Set<FlowMetricRetentionPolicy> ALL;
    static {
        Set<FlowMetricRetentionPolicy> all = new LinkedHashSet<>();
        all.add(CURRENT);
        all.add(LAST_1_MINUTE);
        all.add(LAST_5_MINUTES);
        all.add(LAST_15_MINUTES);
        all.add(LAST_1_HOUR);
        all.add(LAST_24_HOURS);
        all.add(LIFETIME);
        ALL = Collections.unmodifiableSet(all);
    }

    public static Set<FlowMetricRetentionPolicy> all() {
        return ALL;
    }
}
