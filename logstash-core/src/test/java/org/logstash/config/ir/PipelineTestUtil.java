package org.logstash.config.ir;

import java.util.Collection;
import java.util.function.Consumer;
import org.logstash.config.ir.compiler.AbstractOutputDelegatorExt;
import org.logstash.config.ir.compiler.JavaOutputDelegatorExt;
import org.logstash.ext.JrubyEventExtLibrary;
import org.logstash.instrument.metrics.NullMetricExt;

public final class PipelineTestUtil {

    private PipelineTestUtil() {
        //Utility Class
    }

    public static AbstractOutputDelegatorExt buildOutput(
        final Consumer<Collection<JrubyEventExtLibrary.RubyEvent>> consumer) {
        return JavaOutputDelegatorExt.create(
            "someClassName", "someId", NullMetricExt.create(), consumer, () -> {},
            () -> {}
        );
    }
}
