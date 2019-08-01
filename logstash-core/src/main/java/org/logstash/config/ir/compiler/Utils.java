package org.logstash.config.ir.compiler;

import org.logstash.ext.JrubyEventExtLibrary;

import java.util.Collection;
import java.util.Comparator;
import java.util.List;

/**
 * Static utility methods that replace common blocks of generated code in the Java execution.
 */
public class Utils {

    @SuppressWarnings({"unchecked", "rawtypes"})
    // has field1.compute(batchArg, flushArg, shutdownArg) passed as input
    public static void copyNonCancelledEvents(Collection<JrubyEventExtLibrary.RubyEvent> input, List output) {
        for (JrubyEventExtLibrary.RubyEvent e : input) {
            if (!(e.getEvent().isCancelled())) {
                output.add(e);
            }
        }
    }

    @SuppressWarnings({"unchecked", "rawtypes"})
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

    /**
     * Comparator for events based on the sequence of their instantiation. Used to maintain input event
     * ordering with a single pipeline worker.
     */
    public static class EventSequenceComparator implements Comparator<JrubyEventExtLibrary.RubyEvent> {

        @Override
        public int compare(JrubyEventExtLibrary.RubyEvent o1, JrubyEventExtLibrary.RubyEvent o2) {
            return Long.compare(o1.sequence(), o2.sequence());
        }
    }

}
