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

import org.jruby.RubySymbol;
import org.logstash.RubyUtil;

public final class MetricKeys {

    private MetricKeys() {
        // Constant Holder
    }

    public static final RubySymbol PIPELINES_KEY = RubyUtil.RUBY.newSymbol("pipelines");

    public static final RubySymbol NAME_KEY = RubyUtil.RUBY.newSymbol("name");

    public static final RubySymbol EVENTS_KEY = RubyUtil.RUBY.newSymbol("events");

    public static final RubySymbol OUT_KEY = RubyUtil.RUBY.newSymbol("out");

    public static final RubySymbol IN_KEY = RubyUtil.RUBY.newSymbol("in");

    public static final RubySymbol PLUGINS_KEY = RubyUtil.RUBY.newSymbol("plugins");

    public static final RubySymbol INPUTS_KEY = RubyUtil.RUBY.newSymbol("inputs");

    public static final RubySymbol FILTERS_KEY = RubyUtil.RUBY.newSymbol("filters");

    public static final RubySymbol OUTPUTS_KEY = RubyUtil.RUBY.newSymbol("outputs");

    public static final RubySymbol DURATION_IN_MILLIS_KEY = RubyUtil.RUBY.newSymbol("duration_in_millis");

    public static final RubySymbol PUSH_DURATION_KEY = RubyUtil.RUBY.newSymbol("queue_push_duration_in_millis");

    public static final RubySymbol PAGE_CAPACITY_IN_BYTES_KEY = RubyUtil.RUBY.newSymbol("page_capacity_in_bytes");

    public static final RubySymbol MAX_QUEUE_SIZE_IN_BYTES_KEY = RubyUtil.RUBY.newSymbol("max_queue_size_in_bytes");

    public static final RubySymbol MAX_QUEUE_UNREAD_EVENTS_KEY = RubyUtil.RUBY.newSymbol("max_unread_events");

    public static final RubySymbol QUEUE_SIZE_IN_BYTES_KEY = RubyUtil.RUBY.newSymbol("queue_size_in_bytes");

    public static final RubySymbol FREE_SPACE_IN_BYTES_KEY = RubyUtil.RUBY.newSymbol("free_space_in_bytes");

    public static final RubySymbol STORAGE_TYPE_KEY = RubyUtil.RUBY.newSymbol("storage_type");

    public static final RubySymbol PATH_KEY = RubyUtil.RUBY.newSymbol("path");

    public static final RubySymbol TYPE_KEY = RubyUtil.RUBY.newSymbol("type");

    public static final RubySymbol QUEUE_KEY = RubyUtil.RUBY.newSymbol("queue");

    public static final RubySymbol CAPACITY_KEY = RubyUtil.RUBY.newSymbol("capacity");

    public static final RubySymbol DLQ_KEY = RubyUtil.RUBY.newSymbol("dlq");

    public static final RubySymbol STORAGE_POLICY_KEY = RubyUtil.RUBY.newSymbol("storage_policy");

    public static final RubySymbol DROPPED_EVENTS_KEY = RubyUtil.RUBY.newSymbol("dropped_events");

    public static final RubySymbol EXPIRED_EVENTS_KEY = RubyUtil.RUBY.newSymbol("expired_events");

    public static final RubySymbol LAST_ERROR_KEY = RubyUtil.RUBY.newSymbol("last_error");

    public static final RubySymbol FILTERED_KEY = RubyUtil.RUBY.newSymbol("filtered");

    public static final RubySymbol STATS_KEY = RubyUtil.RUBY.newSymbol("stats");

    // Flow metric keys
    public static final RubySymbol FLOW_KEY = RubyUtil.RUBY.newSymbol("flow");

    public static final RubySymbol INPUT_THROUGHPUT_KEY = RubyUtil.RUBY.newSymbol("input_throughput");

    public static final RubySymbol OUTPUT_THROUGHPUT_KEY = RubyUtil.RUBY.newSymbol("output_throughput");

    public static final RubySymbol FILTER_THROUGHPUT_KEY = RubyUtil.RUBY.newSymbol("filter_throughput");

    public static final RubySymbol QUEUE_BACKPRESSURE_KEY = RubyUtil.RUBY.newSymbol("queue_backpressure");

    public static final RubySymbol WORKER_CONCURRENCY_KEY = RubyUtil.RUBY.newSymbol("worker_concurrency");

    public static final RubySymbol WORKER_MILLIS_PER_EVENT_KEY = RubyUtil.RUBY.newSymbol("worker_millis_per_event");

    public static final RubySymbol WORKER_UTILIZATION_KEY = RubyUtil.RUBY.newSymbol("worker_utilization");

    public static final RubySymbol UPTIME_IN_MILLIS_KEY = RubyUtil.RUBY.newSymbol("uptime_in_millis");

    public static final RubySymbol QUEUE_PERSISTED_GROWTH_EVENTS_KEY = RubyUtil.RUBY.newSymbol("queue_persisted_growth_events");

    public static final RubySymbol QUEUE_PERSISTED_GROWTH_BYTES_KEY = RubyUtil.RUBY.newSymbol("queue_persisted_growth_bytes");

    public static final RubySymbol PLUGIN_THROUGHPUT_KEY = RubyUtil.RUBY.newSymbol("throughput");

    public static final RubySymbol ENCODE_KEY = RubyUtil.RUBY.newSymbol("encode");

    public static final RubySymbol DECODE_KEY = RubyUtil.RUBY.newSymbol("decode");

    public static final RubySymbol WRITES_IN_KEY = RubyUtil.RUBY.newSymbol("writes_in");

}
