package org.logstash.config.ir.compiler;

import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Collection;
import java.util.List;

/**
 * Static utility methods that replace common blocks of generated code in the Java execution.
 */
public class Utils {

    // has field1.compute(batchArg, flushArg, shutdownArg) passed as input
    public static void copyNonCancelledEvents(Collection<JrubyEventExtLibrary.RubyEvent> input, List output) {
        for (JrubyEventExtLibrary.RubyEvent e : input) {
            if (!(e.getEvent().isCancelled())) {
                output.add(e);
            }
        }
    }

    public static void filterEvents(Collection<JrubyEventExtLibrary.RubyEvent> input, EventCondition filter,
                                    List fulfilled, List unfulfilled) {
        for (JrubyEventExtLibrary.RubyEvent e : input) {
            if (filter.fulfilled(e)) {
                fulfilled.add(e);
            } else {
                unfulfilled.add(e);
            }
        }
    }

}
