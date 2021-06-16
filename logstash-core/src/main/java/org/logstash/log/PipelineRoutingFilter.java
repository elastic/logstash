package org.logstash.log;

import org.apache.logging.log4j.core.Appender;
import org.apache.logging.log4j.core.Core;
import org.apache.logging.log4j.core.LogEvent;
import org.apache.logging.log4j.core.config.plugins.Plugin;
import org.apache.logging.log4j.core.config.plugins.PluginFactory;
import org.apache.logging.log4j.core.filter.AbstractFilter;

/**
 * Custom filter to avoid that pipeline tagged log events goes in global appender.
 * */
@Plugin(name = "PipelineRoutingFilter", category = Core.CATEGORY_NAME, elementType = Appender.ELEMENT_TYPE, printObject = true)
public final class PipelineRoutingFilter extends AbstractFilter {

    private final boolean isSeparateLogs;

    /**
     * Factory method to instantiate the filter
     * */
    @PluginFactory
    public static PipelineRoutingFilter createFilter() {
        return new PipelineRoutingFilter();
    }

    /**
     * Avoid direct instantiation of the filter
     * */
    private PipelineRoutingFilter() {
        isSeparateLogs = Boolean.getBoolean("ls.pipeline.separate_logs");
    }

    /**
     * Contains the main logic to execute in filtering.
     *
     * Deny the logging of an event when separate logs feature is enabled and the event is fish tagged with a
     * pipeline id.
     *
     * @param event the log to filter.
     * */
    @Override
    public Result filter(LogEvent event) {
        final boolean directedToPipelineLog = isSeparateLogs &&
                event.getContextData().containsKey("pipeline.id");
        if (directedToPipelineLog) {
            return Result.DENY;
        }
        return Result.NEUTRAL;
    }
}
