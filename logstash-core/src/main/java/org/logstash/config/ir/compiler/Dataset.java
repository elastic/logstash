package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.logstash.RubyUtil;
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

    /**
     * {@link Dataset} resulting from applying a backing {@link RubyIntegration.Filter} to all
     * dependent {@link Dataset}.
     */
    final class FilteredDataset implements Dataset {

        private final Collection<Dataset> parents;

        private final RubyIntegration.Filter func;

        private final Collection<JrubyEventExtLibrary.RubyEvent> data;

        private final Collection<JrubyEventExtLibrary.RubyEvent> buffer;

        private boolean done;

        public FilteredDataset(Collection<Dataset> parents, final RubyIntegration.Filter func) {
            this.parents = parents;
            this.func = func;
            data = new ArrayList<>(5);
            buffer = new ArrayList<>(5);
            done = false;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(final RubyArray batch,
            final boolean flush, final boolean shutdown) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(batch, flush, shutdown));
            }
            done = true;
            data.addAll(func.multiFilter(buffer));
            buffer.clear();
            return data;
        }

        @Override
        public void clear() {
            for (final Dataset parent : parents) {
                parent.clear();
            }
            data.clear();
            done = false;
        }
    }

    /**
     * {@link Dataset} resulting from applying a backing {@link RubyIntegration.Filter} that flushes
     * periodically to all dependent {@link Dataset}.
     */
    final class FilteredFlushableDataset implements Dataset {

        public static final RubyHash FLUSH_FINAL = flushOpts(true);

        private static final RubyHash FLUSH_NOT_FINAL = flushOpts(false);

        private final Collection<Dataset> parents;

        private final RubyIntegration.Filter func;

        private final Collection<JrubyEventExtLibrary.RubyEvent> data;

        private final Collection<JrubyEventExtLibrary.RubyEvent> buffer;

        private boolean done;

        public FilteredFlushableDataset(Collection<Dataset> parents,
            final RubyIntegration.Filter func) {
            this.parents = parents;
            this.func = func;
            data = new ArrayList<>(5);
            buffer = new ArrayList<>(5);
            done = false;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(final RubyArray batch,
            final boolean flush, final boolean shutdown) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(batch, flush, shutdown));
            }
            done = true;
            data.addAll(func.multiFilter(buffer));
            if (flush) {
                data.addAll(func.flush(shutdown ? FLUSH_FINAL : FLUSH_NOT_FINAL));
            }
            buffer.clear();
            return data;
        }

        @Override
        public void clear() {
            for (final Dataset parent : parents) {
                parent.clear();
            }
            data.clear();
            done = false;
        }

        private static RubyHash flushOpts(final boolean fin) {
            final RubyHash res = RubyHash.newHash(RubyUtil.RUBY);
            res.put(RubyUtil.RUBY.newSymbol("final"), RubyUtil.RUBY.newBoolean(fin));
            return res;
        }
    }

    /**
     * {@link Dataset} resulting from applying a backing {@link RubyIntegration.Filter} that does
     * flush, but only on shutdown, to all dependent {@link Dataset}.
     */
    final class FilteredShutdownFlushableDataset implements Dataset {

        private final Collection<Dataset> parents;

        private final RubyIntegration.Filter func;

        private final Collection<JrubyEventExtLibrary.RubyEvent> data;

        private final Collection<JrubyEventExtLibrary.RubyEvent> buffer;

        private boolean done;

        public FilteredShutdownFlushableDataset(Collection<Dataset> parents,
            final RubyIntegration.Filter func) {
            this.parents = parents;
            this.func = func;
            data = new ArrayList<>(5);
            buffer = new ArrayList<>(5);
            done = false;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(final RubyArray batch,
            final boolean flush, final boolean shutdown) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(batch, flush, shutdown));
            }
            done = true;
            data.addAll(func.multiFilter(buffer));
            if (flush && shutdown) {
                data.addAll(func.flush(FilteredFlushableDataset.FLUSH_FINAL));
            }
            buffer.clear();
            return data;
        }

        @Override
        public void clear() {
            for (final Dataset parent : parents) {
                parent.clear();
            }
            data.clear();
            done = false;
        }
    }
}
