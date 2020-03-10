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

import co.elastic.logstash.api.*;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.jruby.RubyString;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.builtin.IRubyObject;
import org.junit.Test;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.common.SourceWithMetadata;
import org.logstash.config.ir.ConfigCompiler;
import org.logstash.config.ir.PipelineIR;
import org.logstash.config.ir.RubyEnvTestCase;
import org.logstash.instrument.metrics.NamespacedMetricExt;

import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.Map;
import java.util.function.Consumer;

import static org.junit.Assert.assertEquals;
import static org.logstash.RubyUtil.NAMESPACED_METRIC_CLASS;
import static org.logstash.RubyUtil.RUBY;
import static org.logstash.plugins.MetricTestCase.runRubyScript;

/**
 * Tests for {@link PluginFactoryExt.Plugins}.
 */
public final class PluginFactoryExtTest extends RubyEnvTestCase {

    static class MockInputPlugin implements Input {
        private final String id;

        @SuppressWarnings("unused")
        public MockInputPlugin(String id, Configuration config, Context ctx) {
            this.id = id;
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return Collections.emptyList();
        }

        @Override
        public String getId() {
            return id;
        }

        @Override
        public void start(Consumer<Map<String, Object>> writer) {
        }

        @Override
        public void stop() {
        }

        @Override
        public void awaitStop() throws InterruptedException {
        }
    }

    @Test
    public void testPluginIdResolvedWithEnvironmentVariables() throws IncompleteSourceWithMetadataException {
        PluginFactoryExt.PluginResolver mockPluginResolver = wrapWithSearchable(MockInputPlugin.class);

        SourceWithMetadata sourceWithMetadata = new SourceWithMetadata("proto", "path", 1, 8, "input {mockinput{ id => \"${CUSTOM}\"}} output{mockoutput{}}");
        final PipelineIR pipelineIR = compilePipeline(sourceWithMetadata);

        PluginFactoryExt.Metrics metricsFactory = createMetricsFactory();
        PluginFactoryExt.ExecutionContext execContextFactory = createExecutionContextFactory();
        Map<String, String> envVars = new HashMap<>();
        envVars.put("CUSTOM", "test");
        PluginFactoryExt.Plugins sut = new PluginFactoryExt.Plugins(RubyUtil.RUBY, RubyUtil.PLUGIN_FACTORY_CLASS,
                mockPluginResolver);
        sut.init(pipelineIR, metricsFactory, execContextFactory, RubyUtil.FILTER_DELEGATOR_CLASS, envVars::get);

        RubyString pluginName = RubyUtil.RUBY.newString("mockinput");

        // Exercise
        IRubyObject pluginInstance = sut.buildInput(pluginName, sourceWithMetadata, RubyHash.newHash(RubyUtil.RUBY),
                Collections.emptyMap());

        //Verify
        IRubyObject id = pluginInstance.callMethod(RUBY.getCurrentContext(), "id");
        assertEquals("Resolved config setting MUST be evaluated with substitution", envVars.get("CUSTOM"), id.toString());
    }

    @SuppressWarnings("rawtypes")
    private static PipelineIR compilePipeline(SourceWithMetadata sourceWithMetadata) {
        RubyArray sourcesWithMetadata = RubyUtil.RUBY.newArray(JavaUtil.convertJavaToRuby(
                RubyUtil.RUBY, sourceWithMetadata));

        return ConfigCompiler.configToPipelineIR(sourcesWithMetadata, false);
    }

    private static PluginFactoryExt.ExecutionContext createExecutionContextFactory() {
        PluginFactoryExt.ExecutionContext execContextFactory = new PluginFactoryExt.ExecutionContext(RubyUtil.RUBY,
                RubyUtil.EXECUTION_CONTEXT_FACTORY_CLASS);
        execContextFactory.initialize(RubyUtil.RUBY.getCurrentContext(), null, null,
                RubyUtil.RUBY.newString("no DLQ"));
        return execContextFactory;
    }

    private static PluginFactoryExt.Metrics createMetricsFactory() {
        final IRubyObject metricWithCollector =
                runRubyScript("require \"logstash/instrument/collector\"\n" +
                        "metricWithCollector = LogStash::Instrument::Metric.new(LogStash::Instrument::Collector.new)");

        NamespacedMetricExt metric = new NamespacedMetricExt(RUBY, NAMESPACED_METRIC_CLASS)
                .initialize(RUBY.getCurrentContext(), metricWithCollector, RUBY.newEmptyArray());


        PluginFactoryExt.Metrics metricsFactory = new PluginFactoryExt.Metrics(RubyUtil.RUBY, RubyUtil.PLUGIN_METRIC_FACTORY_CLASS);
        metricsFactory.initialize(RubyUtil.RUBY.getCurrentContext(), RubyUtil.RUBY.newString("main"), metric);
        return metricsFactory;
    }

    private static PluginFactoryExt.PluginResolver wrapWithSearchable(final Class<? extends Input> pluginClass) {
        return new PluginFactoryExt.PluginResolver() {
            @Override
            public PluginLookup.PluginClass resolve(PluginLookup.PluginType type, String name) {
                return new PluginLookup.PluginClass() {
                    @Override
                    public PluginLookup.PluginLanguage language() {
                        return PluginLookup.PluginLanguage.JAVA;
                    }

                    @Override
                    public Object klass() {
                        return pluginClass;
                    }
                };
            }
        };
    }
}