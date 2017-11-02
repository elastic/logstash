package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
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

    /**
     * Root {@link Dataset}s at the beginning of the execution tree that simply pass through
     * the given set of {@link JrubyEventExtLibrary.RubyEvent} and have no state.
     */
    Collection<Dataset> ROOT_DATASETS = Collections.singleton(
        DatasetCompiler.compile("return batch;", "")
    );

    /**
     * {@link Dataset} that results from the {@code if} branch of its backing
     * {@link EventCondition} being applied to all of its dependencies.
     */
    final class SplitDataset implements Dataset {

        private final Collection<Dataset> parents;

        private final EventCondition func;

        private final Collection<JrubyEventExtLibrary.RubyEvent> trueData;

        private final Collection<JrubyEventExtLibrary.RubyEvent> falseData;

        private final Dataset opposite;

        private boolean done;

        public SplitDataset(final Collection<Dataset> parents,
            final EventCondition eventCondition) {
            this.parents = parents;
            this.func = eventCondition;
            done = false;
            trueData = new ArrayList<>(5);
            falseData = new ArrayList<>(5);
            opposite = new Dataset.SplitDataset.Complement(this, falseData);
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(final RubyArray batch,
            final boolean flush, final boolean shutdown) {
            if (done) {
                return trueData;
            }
            for (final Dataset set : parents) {
                for (final JrubyEventExtLibrary.RubyEvent event
                    : set.compute(batch, flush, shutdown)) {
                    if (func.fulfilled(event)) {
                        trueData.add(event);
                    } else {
                        falseData.add(event);
                    }
                }
            }
            done = true;
            return trueData;
        }

        @Override
        public void clear() {
            for (final Dataset parent : parents) {
                parent.clear();
            }
            trueData.clear();
            falseData.clear();
            done = false;
        }

        public Dataset right() {
            return opposite;
        }

        /**
         * Complementary {@link Dataset} to a {@link Dataset.SplitDataset} representing the
         * negative branch of the {@code if} statement.
         */
        private static final class Complement implements Dataset {

            /**
             * Positive branch of underlying {@code if} statement.
             */
            private final Dataset parent;

            /**
             * This collection is shared with {@link Dataset.SplitDataset.Complement#parent} and
             * mutated when calling its {@code compute} method. This class does not directly compute
             * it.
             */
            private final Collection<JrubyEventExtLibrary.RubyEvent> data;

            private boolean done;

            /**
             * Ctor.
             * @param left Positive Branch {@link Dataset.SplitDataset}
             * @param complement Collection of {@link JrubyEventExtLibrary.RubyEvent}s that did
             * not match {@code left}
             */
            private Complement(
                final Dataset left, final Collection<JrubyEventExtLibrary.RubyEvent> complement) {
                this.parent = left;
                data = complement;
            }

            @Override
            public Collection<JrubyEventExtLibrary.RubyEvent> compute(
                final RubyArray batch, final boolean flush, final boolean shutdown) {
                if (done) {
                    return data;
                }
                parent.compute(batch, flush, shutdown);
                done = true;
                return data;
            }

            @Override
            public void clear() {
                parent.clear();
                done = false;
            }
        }
    }

}
