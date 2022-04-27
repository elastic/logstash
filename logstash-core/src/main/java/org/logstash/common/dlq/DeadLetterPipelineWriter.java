package org.logstash.common.dlq;

import com.google.common.collect.Lists;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.plugins.pipeline.PipelineBus;
import org.logstash.plugins.pipeline.PipelineOutput;

import java.io.IOException;
import java.util.HashMap;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;
import java.util.concurrent.atomic.LongAdder;

import static org.logstash.RubyUtil.RUBY;


public class DeadLetterPipelineWriter implements IDeadLetterQueueWriter {
    private static final Logger LOGGER = LogManager.getLogger(DeadLetterPipelineWriter.class);
    private final String sourcePipeline;
    private final String deadLetterPipeline;
    private final PipelineBus pipelineBus;
    private final PipelineOutput deadLetterPipelineOutput;
    private final LongAdder eventsWritten = new LongAdder();
    private final AtomicBoolean isOpen = new AtomicBoolean(true);

    public DeadLetterPipelineWriter(final String sourcePipeline, final String deadLetterPipeline, final PipelineBus pipelineBus) {
        this.sourcePipeline = sourcePipeline;
        this.deadLetterPipeline = deadLetterPipeline;
        this.pipelineBus = pipelineBus;

        deadLetterPipelineOutput = new PipelineOutput() {
            @Override
            public int hashCode() {
                return super.hashCode();
            }

            public String toString(){
                return String.format("Dead Letter Pipeline: [Dead Letter Pipeline: %s, Originating Pipeline: %s]",
                                     deadLetterPipeline, sourcePipeline);
            }
        };
        LOGGER.warn("Registering failure pipeline from {} to {}", sourcePipeline, deadLetterPipeline);
        pipelineBus.registerSender(deadLetterPipelineOutput, Lists.newArrayList(deadLetterPipeline));
    }

    @Override
    public void writeEntry(Event event, Map<String, Object> metadata) throws IOException {
        LOGGER.debug("Sending event {} to {}", event, deadLetterPipeline);
        Event newEvent = new Event();
        String errorKey = "[error]";
        String dlpRoute = (String) event.getField("[@metadata][dlp_route]");
        if (dlpRoute == null || dlpRoute.isEmpty()){
            dlpRoute = deadLetterPipeline;
            newEvent.setField("[event][original]", event.toJson());
        } else {
            newEvent.setField("[event][original]", event.getField("[event][original]"));
            String[] path = dlpRoute.split(",");
            for (String pathPart : path){
                if (pathPart.equals(deadLetterPipeline)){
                    LOGGER.warn("DLP Cycle detected: Event{} has already been through {}, path={}", event, pathPart, dlpRoute);
                    return;
                }
            }
            dlpRoute = String.format("%s,%s", dlpRoute, deadLetterPipeline);
        }
        newEvent.setField(errorKey, metadata);
        newEvent.setField("[@metadata][dlp_route]", dlpRoute);
        newEvent.setField(String.format("%s[source][pipeline]", errorKey), sourcePipeline);
        JrubyEventExtLibrary.RubyEvent er = JrubyEventExtLibrary.RubyEvent.newRubyEvent(RUBY, newEvent);
        pipelineBus.sendEvents(deadLetterPipelineOutput, Lists.newArrayList(er), true);
        eventsWritten.increment();
    }

    @Override
    public void writeEntry(Event event, String pluginName, String pluginId, String reason) throws IOException {
        Map<String, Object> metadata = new HashMap<>();
        Map<String, String> source = new HashMap<>();
        source.put("plugin_name", pluginName);
        source.put("plugin_id", pluginId);
        metadata.put("source", source);
        metadata.put("message", reason);
        writeEntry(event, metadata);
    }

    @Override
    public void close() {
        if (isOpen.compareAndSet(true, false)) {
            pipelineBus.unregisterSender(deadLetterPipelineOutput, Lists.newArrayList(deadLetterPipeline));
        }
    }

    @Override
    public boolean isOpen() {
        return isOpen.get();
    }

    @Override
    public long getCurrentQueueSize() {
        return eventsWritten.longValue();
    }
}
