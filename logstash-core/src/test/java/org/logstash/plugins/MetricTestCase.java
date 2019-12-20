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


package org.logstash.plugins;

import co.elastic.logstash.api.Metric;
import com.google.common.base.Joiner;
import org.jruby.RubyFixnum;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.java.proxies.ConcreteJavaProxy;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Before;
import org.logstash.RubyUtil;
import org.logstash.config.ir.RubyEnvTestCase;
import org.logstash.execution.ExecutionContextExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.NamespacedMetricExt;

import static org.logstash.RubyUtil.*;

public abstract class MetricTestCase extends RubyEnvTestCase {
    protected AbstractNamespacedMetricExt metric;
    protected ExecutionContextExt executionContext;

    @Before
    public void setup() {
        final IRubyObject metricWithCollector =
            runRubyScript("require \"logstash/instrument/collector\"\n" +
                              "metricWithCollector = LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new)");

        metric = new NamespacedMetricExt(RUBY, NAMESPACED_METRIC_CLASS)
            .initialize(RUBY.getCurrentContext(), metricWithCollector, RUBY.newEmptyArray());
        executionContext = new ExecutionContextExt(RUBY, EXECUTION_CONTEXT_CLASS);
    }

    public static IRubyObject runRubyScript(String script) {
        IRubyObject m = RUBY.evalScriptlet(script);
        return m;
    }

    protected RubyHash getMetricStore(String[] path) {
        RubyHash metricStore = (RubyHash) metric.collector(RUBY.getCurrentContext())
            .callMethod(RUBY.getCurrentContext(), "snapshot_metric")
            .callMethod(RUBY.getCurrentContext(), "metric_store")
            .callMethod(RUBY.getCurrentContext(), "get_with_path", RUBY.newString(Joiner.on("/").join(path)));

        RubyHash rh = metricStore;
        for (String p : path) {
            rh = (RubyHash) rh.op_aref(RUBY.getCurrentContext(), RUBY.newSymbol(p));
        }
        return rh;
    }

    protected String getMetricStringValue(RubyHash metricStore, String symbolName) {
        ConcreteJavaProxy counter = (ConcreteJavaProxy) metricStore.op_aref(RUBY.getCurrentContext(), RUBY.newSymbol(symbolName));
        RubyString value = (RubyString) counter.callMethod("value");
        return value.asJavaString();
    }

    protected long getMetricLongValue(RubyHash metricStore, String symbolName) {
        ConcreteJavaProxy counter = (ConcreteJavaProxy) metricStore.op_aref(RUBY.getCurrentContext(), RUBY.newSymbol(symbolName));
        RubyFixnum count = (RubyFixnum) counter.callMethod("value");
        return count.getLongValue();
    }

    protected Metric getInstance() {
        return new RootMetricImpl(RubyUtil.RUBY.getCurrentContext(), this.metric);
    }
}
