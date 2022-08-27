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


package org.logstash.execution;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.jruby.Ruby;
import org.jruby.RubyArray;
import org.jruby.RubyBoolean;
import org.jruby.RubyClass;
import org.jruby.RubySymbol;
import org.jruby.anno.JRubyClass;
import org.jruby.anno.JRubyMethod;
import org.jruby.javasupport.JavaUtil;
import org.jruby.runtime.ThreadContext;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.common.IncompleteSourceWithMetadataException;
import org.logstash.config.ir.CompiledPipeline;
import org.logstash.execution.queue.QueueWriter;
import org.logstash.ext.JRubyWrappedWriteClientExt;
import org.logstash.instrument.metrics.AbstractNamespacedMetricExt;
import org.logstash.instrument.metrics.FlowMetric;
import org.logstash.instrument.metrics.MetricKeys;
import org.logstash.instrument.metrics.UptimeMetric;
import org.logstash.instrument.metrics.counter.LongCounter;
import org.logstash.plugins.factory.ExecutionContextFactoryExt;
import org.logstash.plugins.factory.PluginMetricsFactoryExt;
import org.logstash.plugins.factory.PluginFactoryExt;

import java.security.NoSuchAlgorithmException;
import java.time.temporal.ChronoUnit;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Map;
import java.util.Objects;
import java.util.stream.Stream;

/**
 * JRuby extension used as parent for Ruby's JavaPipelines
 * */
@JRubyClass(name = "JavaBasePipeline")
public final class JavaBasePipelineExt extends AbstractPipelineExt {

    private static final long serialVersionUID = 1L;

    private static final Logger LOGGER = LogManager.getLogger(JavaBasePipelineExt.class);

    private transient CompiledPipeline lirExecution;

    private @SuppressWarnings("rawtypes") RubyArray inputs;

    private @SuppressWarnings("rawtypes") RubyArray filters;

    private @SuppressWarnings("rawtypes") RubyArray outputs;

    private Map<RubySymbol, FlowMetric> flowMetrics;

    private AbstractNamespacedMetricExt eventsMetric;

    private AbstractNamespacedMetricExt flowMetric;

    public JavaBasePipelineExt(final Ruby runtime, final RubyClass metaClass) {
        super(runtime, metaClass);
    }

    @JRubyMethod(required = 4)
    public JavaBasePipelineExt initialize(final ThreadContext context, final IRubyObject[] args)
        throws IncompleteSourceWithMetadataException, NoSuchAlgorithmException {
        initialize(context, args[0], args[1], args[2]);
        lirExecution = new CompiledPipeline(
            lir,
            new PluginFactoryExt(context.runtime, RubyUtil.PLUGIN_FACTORY_CLASS).init(
                lir,
                new PluginMetricsFactoryExt(
                    context.runtime, RubyUtil.PLUGIN_METRICS_FACTORY_CLASS
                ).initialize(context, pipelineId(), metric()),
                new ExecutionContextFactoryExt(
                    context.runtime, RubyUtil.EXECUTION_CONTEXT_FACTORY_CLASS
                ).initialize(context, args[3], this, dlqWriter(context)),
                RubyUtil.FILTER_DELEGATOR_CLASS
            ),
            getSecretStore(context)
        );
        inputs = RubyArray.newArray(context.runtime, lirExecution.inputs());
        filters = RubyArray.newArray(context.runtime, lirExecution.filters());
        outputs = RubyArray.newArray(context.runtime, lirExecution.outputs());
        if (getSetting(context, "config.debug").isTrue() && LOGGER.isDebugEnabled()) {
            LOGGER.debug(
                "Compiled pipeline code for pipeline {} : {}", pipelineId(),
                lir.getGraph().toString()
            );
        }
        return this;
    }

    @JRubyMethod(name = "lir_execution")
    public IRubyObject lirExecution(final ThreadContext context) {
        return JavaUtil.convertJavaToUsableRubyObject(context.runtime, lirExecution);
    }

    @JRubyMethod
    @SuppressWarnings("rawtypes")
    public RubyArray inputs() {
        return inputs;
    }

    @JRubyMethod
    @SuppressWarnings("rawtypes")
    public RubyArray filters() {
        return filters;
    }

    @JRubyMethod
    @SuppressWarnings("rawtypes")
    public RubyArray outputs() {
        return outputs;
    }

    @JRubyMethod(name = "reloadable?")
    public RubyBoolean isReloadable(final ThreadContext context) {
        return isConfiguredReloadable(context).isTrue() && reloadablePlugins(context).isTrue()
            ? context.tru : context.fals;
    }

    @JRubyMethod(name = "reloadable_plugins?")
    public RubyBoolean reloadablePlugins(final ThreadContext context) {
        return nonReloadablePlugins(context).isEmpty() ? context.tru : context.fals;
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
    @JRubyMethod(name = "non_reloadable_plugins")
    public RubyArray nonReloadablePlugins(final ThreadContext context) {
        final RubyArray result = RubyArray.newArray(context.runtime);
        Stream.of(inputs, outputs, filters).flatMap(
            plugins -> ((Collection<IRubyObject>) plugins).stream()
        ).filter(
            plugin -> !plugin.callMethod(context, "reloadable?").isTrue()
        ).forEach(result::add);
        return result;
    }

    @JRubyMethod(name = "shutdown_requested?")
    public IRubyObject isShutdownRequested(final ThreadContext context) {
        throw new IllegalStateException("Pipeline implementation does not provide `shutdown_requested?`, which is a Logstash internal error.");
    }

    @JRubyMethod(name = "register_pipeline_flow_rates")
    public IRubyObject registerPipelineFlowRatesMetric(final ThreadContext context) {
        UptimeMetric uptimeMetric = new UptimeMetric(pipelineId().asJavaString() + ".uptime_in_millis", ChronoUnit.MILLIS);
        // TODO: generate and add all target metrics
        Map<RubySymbol, FlowMetric> metricMap = new HashMap<>();
        Arrays.asList(MetricKeys.FLOW_KEYS).forEach(key -> {
            if (MetricKeys.CONCURRENCY_KEY.eql(key)) {

            } else if (MetricKeys.INPUT_THROUGHPUT_KEY.eql(key)) {
                metricMap.put(key, createFlowMetric(context, MetricKeys.IN_KEY, uptimeMetric));
            } else if (MetricKeys.FILTER_THROUGHPUT_KEY.eql(key)) {
                metricMap.put(key, createFlowMetric(context, MetricKeys.FILTERED_KEY, uptimeMetric));
            } else if (MetricKeys.OUTPUT_THROUGHPUT_KEY.eql(key)) {
                metricMap.put(key, createFlowMetric(context, MetricKeys.OUT_KEY, uptimeMetric));
            } else if (MetricKeys.BACKPRESSURE_KEY.eql(key)) {

            }
        });
        flowMetrics = Map.copyOf(metricMap);
        return context.nil;
    }

    @JRubyMethod(name = "collect_pipeline_flow_rates")
    public IRubyObject collectPipelineFlowRates(final ThreadContext context) {
        for (RubySymbol key : flowMetrics.keySet()) {
            flowMetrics.get(key).capture();
        }
        return context.nil;
    }

    @JRubyMethod(name = "store_pipeline_flow_rates")
    public IRubyObject fetchPipelineFlowRates(final ThreadContext context) {
        if (Objects.isNull(flowMetric)) {
            flowMetric = getMetric(context,
                    MetricKeys.STATS_KEY, MetricKeys.PIPELINES_KEY,
                    pipelineId().asString().intern(), MetricKeys.FLOW_KEY);
        }

        for (RubySymbol key : flowMetrics.keySet()) {
            final AbstractNamespacedMetricExt metric = flowMetric.namespace(
                    context, RubyArray.newArray(context.runtime, key));
            Map<String, Double> rates = flowMetrics.get(key).getAvailableRates();
            System.out.println("Available rates, size: " + rates.size());
            rates.forEach((rateKey, value) -> {
                System.out.println("[Rates] Name: " + key + ", rate: " + value);
                metric.gauge(context, RubyUtil.RUBY.newSymbol(rateKey), context.runtime.newFloat(value));
            });
        }

        return context.nil;
    }

    public QueueWriter getQueueWriter(final String inputName) {
        return new JRubyWrappedWriteClientExt(RubyUtil.RUBY, RubyUtil.WRAPPED_WRITE_CLIENT_CLASS)
            .initialize(
                RubyUtil.RUBY.getCurrentContext(),
                new IRubyObject[]{
                    inputQueueClient(), pipelineId().convertToString().intern(),
                    metric(), RubyUtil.RUBY.newSymbol(inputName)
                }
            );
    }

    private FlowMetric createFlowMetric(final ThreadContext context,
                               final RubySymbol metricKey,
                               final UptimeMetric uptimeMetric) {
        if (Objects.isNull(eventsMetric)) {
            eventsMetric = getMetric(context,
                    MetricKeys.STATS_KEY, MetricKeys.PIPELINES_KEY, pipelineId(), MetricKeys.EVENTS_KEY);
        }

        LongCounter inMetric = LongCounter.fromRubyBase(eventsMetric, metricKey);
        return new FlowMetric(inMetric, uptimeMetric);
    }
}
