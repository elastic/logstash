package org.logstash.common.dlq;

import com.google.common.collect.Lists;
import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.logstash.Event;
import org.logstash.execution.AbstractPipelineExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.plugins.pipeline.PipelineBus;
import org.logstash.plugins.pipeline.PipelineOutput;

import java.io.IOException;

import static org.logstash.RubyUtil.RUBY;

public class FailurePipelineWriter implements IDeadLetterQueueWriter {
    private static final Logger LOGGER = LogManager.getLogger(FailurePipelineWriter.class);
    private final String id;
    private final String sourcePipeline;
    private final String thisPipeline;
    private final PipelineBus pipelineBus;
    private PipelineOutput dlqPipelineOutput;

    public FailurePipelineWriter(String id, String sourcePipeline, String failurePipeline, PipelineBus pipelineBus) {
        this.id = id;
        this.sourcePipeline = sourcePipeline;
        this.thisPipeline = failurePipeline;
        this.pipelineBus = pipelineBus;
        dlqPipelineOutput = new PipelineOutput() {
            @Override
            public int hashCode() {
                return super.hashCode();
            }
        };
        LOGGER.warn("Registering failure pipeline from {} to {}", sourcePipeline, failurePipeline);
        pipelineBus.registerSender(dlqPipelineOutput, Lists.newArrayList(failurePipeline));
    }
    @Override
    public void writeEntry(Event event, String pluginName, String pluginId, String reason) throws IOException {
        LOGGER.warn("Sending event {} to {}", event, thisPipeline);
        Event newEvent = new Event();

        String dlqPath = (String) event.getField("[@metadata][dlq_path]");
        if (dlqPath == null || dlqPath.isEmpty()){
            dlqPath = thisPipeline;
        } else {
            String[] path = dlqPath.split(",");
            for (String pathPart : path){
                if (pathPart.equals(thisPipeline)){
                    LOGGER.warn("DLQ Cycle detected: Event has already been through {}, path={}", event, pathPart, dlqPath);
                    return;
                }
            }
            dlqPath = String.format("%s,%s", dlqPath, thisPipeline);
        }
        newEvent.setField("[@metadata][dlq_path]", dlqPath);
        newEvent.setField("[_meta][dlq_path]", dlqPath);
        newEvent.setField("[_meta][dlq]", true);
        newEvent.setField("[message]", event.toJson());
        newEvent.setField("[error][source_pipeline]", sourcePipeline);
        newEvent.setField("[error][plugin_type]",pluginName);
        newEvent.setField("[error][plugin_id]", pluginId);
        newEvent.setField("[error][message]", reason);
        JrubyEventExtLibrary.RubyEvent er = JrubyEventExtLibrary.RubyEvent.newRubyEvent(RUBY, newEvent);
        pipelineBus.sendEvents(dlqPipelineOutput, Lists.newArrayList(er), true);
    }

    @Override
    public void close() {

    }

    @Override
    public boolean isOpen() {
        return true;
    }

    @Override
    public long getCurrentQueueSize() {
        return 0;
    }
}
