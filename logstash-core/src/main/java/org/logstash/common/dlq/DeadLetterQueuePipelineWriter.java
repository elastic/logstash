package org.logstash.common.dlq;

import com.google.common.collect.Lists;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.plugins.pipeline.PipelineBus;
import org.logstash.plugins.pipeline.PipelineOutput;

import java.io.IOException;

import static org.logstash.RubyUtil.RUBY;

public class DeadLetterQueuePipelineWriter implements IDeadLetterQueueWriter {

    private final String id;
    private final String pipeline;
    private final PipelineBus pipelineBus;
    private PipelineOutput dlqPipelineOutput;

    public DeadLetterQueuePipelineWriter(String id, String pipeline, PipelineBus pipelineBus) {
        this.id = id;
        this.pipeline = pipeline;
        this.pipelineBus = pipelineBus;
        dlqPipelineOutput = new PipelineOutput() {
            @Override
            public int hashCode() {
                return super.hashCode();
            }
        };
        pipelineBus.registerSender(dlqPipelineOutput, Lists.newArrayList("dlq"));
        System.out.println("Creating DLQ Pipeline Writer");
    }
    @Override
    public void writeEntry(Event event, String pluginName, String pluginId, String reason) throws IOException {
        Event newEvent = new Event();

        if (event.getField("[_meta][dlq]") == Boolean.TRUE){
            System.out.println("Not redoing");
        }
        newEvent.setField("[_meta][dlq]", true);
        newEvent.setField("[message]", event.toJson());
        newEvent.setField("[error][source_pipeline]",pipeline);
        newEvent.setField("[error][plugin_type]",pluginName);
        newEvent.setField("[error][plugin_id]", pluginId);
        newEvent.setField("[error][message]", reason);

        JrubyEventExtLibrary.RubyEvent er = JrubyEventExtLibrary.RubyEvent.newRubyEvent(RUBY, newEvent);

        System.out.println("Writing event from: " + pluginName + ": " + pluginId + ": " + reason);
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
