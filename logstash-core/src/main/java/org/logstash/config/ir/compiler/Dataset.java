package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.jruby.RubyArray;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * <p>A data structure backed by a {@link RubyArray} that represents one step of execution flow of a
 * batch is lazily filled with {@link JrubyEventExtLibrary.RubyEvent} computed from its dependent
 * {@link Dataset}.</p>
 * <p>Each {@link Dataset} either represents a filter, output or one branch of an {@code if}
 * statement in a Logstash configuration file.</p>
 * <p>Note: It does seem more natural to use the {@code clear} invocation to set the next
 * batch of input trueData. For now this is intentionally not implemented since we want to clear
 * the trueData stored in the Dataset tree as early as possible and before the output operations
 * finish. Once the whole execution tree including the output operation is implemented in
 * Java, this API can be adjusted as such.</p>
 */
public interface Dataset {

    /**
     * Dataset that does not modify the input events.
     */
    Dataset IDENTITY = new Dataset() {
        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(final RubyArray batch, final boolean flush, final boolean shutdown) {
            return batch;
        }

        @Override
        public void clear() {
        }
    };

    /**
     * Compute the actual contents of the backing {@link RubyArray} and cache them.
     * Repeated invocations will be effectively free.
     * @param batch Input {@link JrubyEventExtLibrary.RubyEvent} received at the root
     * of the execution
     * @param flush True if flushing flushable nodes while traversing the execution
     * @param shutdown True if this is the last call to this instance's compute method because
     * the pipeline it belongs to is shut down
     * @return Computed {@link RubyArray} of {@link JrubyEventExtLibrary.RubyEvent}
     */
    Collection<JrubyEventExtLibrary.RubyEvent> compute(RubyArray batch,
        boolean flush, boolean shutdown);

    /**
     * Removes all data from the instance and all of its parents, making the instance ready for
     * use with a new set of input data.
     */
    void clear();
}
