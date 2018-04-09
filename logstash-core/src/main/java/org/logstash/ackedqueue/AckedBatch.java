package org.logstash.ackedqueue;

import java.io.IOException;
import org.jruby.RubyHash;
import org.jruby.runtime.ThreadContext;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;

public final class AckedBatch {
    private Batch batch;

    public static AckedBatch create(Batch batch) {
        final AckedBatch ackedBatch = new AckedBatch();
        ackedBatch.batch = batch;
        return ackedBatch;
    }

    public RubyHash toRubyHash(ThreadContext context) {
        final RubyHash result = RubyHash.newHash(context.runtime);
        this.batch.getElements().forEach(e -> result.put(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(context.runtime, (Event) e),
            context.tru
            )
        );
        return result;
    }

    public int size() {
        return batch.size();
    }

    public void close() throws IOException {
        batch.close();
    }
}
