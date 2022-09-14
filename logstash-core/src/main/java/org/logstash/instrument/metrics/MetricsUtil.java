package org.logstash.instrument.metrics;

import org.jruby.RubySymbol;
import org.logstash.RubyUtil;

import java.util.Arrays;

public class MetricsUtil {

    public static RubySymbol[] fullNamespacePath(RubySymbol pipelineId, RubySymbol... subPipelineNamespacePath) {
        final RubySymbol[] pipelineNamespacePath = new RubySymbol[] { MetricKeys.STATS_KEY, MetricKeys.PIPELINES_KEY, pipelineId };
        if (subPipelineNamespacePath.length == 0) {
            return pipelineNamespacePath;
        }
        final RubySymbol[] fullNamespacePath = Arrays.copyOf(pipelineNamespacePath, pipelineNamespacePath.length + subPipelineNamespacePath.length);
        System.arraycopy(subPipelineNamespacePath, 0, fullNamespacePath, pipelineNamespacePath.length, subPipelineNamespacePath.length);
        return fullNamespacePath;
    }

    public static RubySymbol[] buildNamespace(final RubySymbol... namespace) {
        return namespace;
    }
}
