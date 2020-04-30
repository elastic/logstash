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

    public static final RubySymbol DURATION_IN_MILLIS_KEY =
        RubyUtil.RUBY.newSymbol("duration_in_millis");

    public static final RubySymbol FILTERED_KEY = RubyUtil.RUBY.newSymbol("filtered");

    public static final RubySymbol STATS_KEY = RubyUtil.RUBY.newSymbol("stats");
}
