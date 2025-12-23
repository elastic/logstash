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

import java.io.Serial;
import java.io.Serializable;

public class HistogramMetricData implements Serializable {
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