package org.logstash.ackedqueue;

import java.io.IOException;
import org.jruby.Ruby;
import org.jruby.RubyBoolean;
import org.jruby.RubyHash;
import org.logstash.Event;
import org.logstash.ext.JrubyEventExtLibrary;

public final class AckedBatch {
    private Batch batch;

    public static AckedBatch create(Batch batch) {
        final AckedBatch ackedBatch = new AckedBatch();
        ackedBatch.batch = batch;
        return ackedBatch;
    }

    public RubyHash toRubyHash(final Ruby runtime) {
        final RubyBoolean trueValue = runtime.getTrue();
        final RubyHash result = RubyHash.newHash(runtime);
        this.batch.getElements().forEach(e -> result.fastASet(
            JrubyEventExtLibrary.RubyEvent.newRubyEvent(runtime, (Event) e),
            trueValue
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
