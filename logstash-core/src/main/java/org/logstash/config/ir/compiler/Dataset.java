package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import org.jruby.RubyArray;
import org.jruby.RubyHash;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * A data structure backed by a {@link RubyArray} that is lazily filled with
 * {@link JrubyEventExtLibrary.RubyEvent} computed from its dependencies.
 * <p>Note: It does seem more natural to use the {@code clear} invocation to set the next
 * batch of input data. For now this is intentionally not implemented since we want to clear
 * the data stored in the Dataset tree as early as possible and before the output operations
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
     * @param options Flush Option hash passed to {@link RubyIntegration.Filter#flush(RubyHash)}
     * @return Computed {@link RubyArray} of {@link JrubyEventExtLibrary.RubyEvent}
     */
    Collection<JrubyEventExtLibrary.RubyEvent> compute(RubyIntegration.Batch batch,
        boolean flush, boolean shutdown, RubyHash options);

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
        new Dataset() {
            @Override
            public Collection<JrubyEventExtLibrary.RubyEvent> compute(
                final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
                final RubyHash options) {
                return batch.collect();
            }

            @Override
            public void clear() {
            }
        }
    );

    /**
     * <p>{@link Dataset} that contains all {@link JrubyEventExtLibrary.RubyEvent} of all of
     * its dependencies and is assumed to be at the end of an execution.</p>
     * This dataset does not require an explicit call to {@link Dataset#clear()} since it will
     * automatically {@code clear} all of its parents.
     */
    final class TerminalDataset implements Dataset {

        /**
         * Empty {@link Collection} returned by this class's
         * {@link Dataset#compute(RubyIntegration.Batch, boolean, boolean, RubyHash)} implementation.
         */
        private static final Collection<JrubyEventExtLibrary.RubyEvent> EMPTY_RETURN =
            Collections.emptyList();

        /**
         * Trivial {@link Dataset} that simply returns an empty collection of elements.
         */
        private static final Dataset TRIVIAL = new Dataset() {

            @Override
            public Collection<JrubyEventExtLibrary.RubyEvent> compute(
                final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
                final RubyHash options) {
                return EMPTY_RETURN;
            }

            @Override
            public void clear() {
            }
        };

        private final Collection<Dataset> parents;

        /**
         * <p>Builds a terminal {@link Dataset} from the given parent {@link Dataset}s.</p>
         * <p>If the given set of parent {@link Dataset} is empty the sum is defined as the
         * trivial dataset that does not invoke any computation whatsoever.</p>
         * The return of a call to
         * {@link Dataset#compute(RubyIntegration.Batch, boolean, boolean, RubyHash)} is always
         * {@link Collections#emptyList()}.
         * @param parents Parent {@link Dataset} to sum and terminate
         * @return Dataset representing the sum of given parent {@link Dataset}
         */
        public static Dataset from(final Collection<Dataset> parents, final boolean debug) {
            final int count = parents.size();
            final Dataset result;
            if (count > 0) {
                if (debug) {
                    result = new Dataset.TerminalDataset.TerminalDebugDataset(parents);
                } else {
                    result = new Dataset.TerminalDataset(parents);
                }
            } else {
                result = TRIVIAL;
            }
            return result;
        }

        private TerminalDataset(final Collection<Dataset> parents) {
            this.parents = parents;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
            final RubyHash options) {
            parents.forEach(dataset -> dataset.compute(batch, flush, shutdown, options));
            this.clear();
            return EMPTY_RETURN;
        }

        @Override
        public void clear() {
            for (final Dataset parent : parents) {
                parent.clear();
            }
        }

        /**
         * <p>{@link Dataset} that contains all {@link JrubyEventExtLibrary.RubyEvent} of all of
         * its dependencies and is assumed to be at the end of an execution.</p>
         * This dataset does not require an explicit call to {@link Dataset#clear()} since it will
         * automatically {@code clear} all of its parents.
         * Unlike {@link Dataset.TerminalDataset} this class will return all
         * {@link JrubyEventExtLibrary.RubyEvent} that passed through it on a call to
         * {@link Dataset#compute(RubyIntegration.Batch, boolean, boolean, RubyHash)}.
         */
        public static final class TerminalDebugDataset implements Dataset {

            private final Collection<Dataset> parents;

            private TerminalDebugDataset(final Collection<Dataset> parents) {
                this.parents = parents;
            }

            @Override
            public Collection<JrubyEventExtLibrary.RubyEvent> compute(
                final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
                final RubyHash options) {
                final Collection<JrubyEventExtLibrary.RubyEvent> res = new ArrayList<>(10);
                parents.forEach(
                    dataset -> res.addAll(dataset.compute(batch, flush, shutdown, options))
                );
                this.clear();
                return res;
            }

            @Override
            public void clear() {
                for (final Dataset parent : parents) {
                    parent.clear();
                }
            }
        }
    }

    /**
     * {@link Dataset} that results from the {@code if} branch of its backing
     * {@link EventCondition} being applied to all of its dependencies.
     */
    final class SplitDataset implements Dataset {

        private final Collection<Dataset> parents;

        private final EventCondition func;

        private final Collection<JrubyEventExtLibrary.RubyEvent> data;

        private final Collection<JrubyEventExtLibrary.RubyEvent> complement;

        private final Dataset opposite;

        private boolean done;

        public SplitDataset(final Collection<Dataset> parents, final EventCondition func) {
            this.parents = parents;
            this.func = func;
            done = false;
            data = new ArrayList<>(5);
            complement = new ArrayList<>(5);
            opposite = new Dataset.SplitDataset.Complement(this, complement);
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
            final RubyHash options) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                for (final JrubyEventExtLibrary.RubyEvent event
                    : set.compute(batch, flush, shutdown, options)) {
                    if (func.fulfilled(event)) {
                        data.add(event);
                    } else {
                        complement.add(event);
                    }
                }
            }
            done = true;
            return data;
        }

        @Override
        public void clear() {
            for (final Dataset parent : parents) {
                parent.clear();
            }
            data.clear();
            complement.clear();
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
            private final Dataset left;

            /**
             * This collection is shared with {@link Dataset.SplitDataset.Complement#left} and 
             * mutated when calling its {@code compute} method. This class does not directly compute
             * it.
             */
            private final Collection<JrubyEventExtLibrary.RubyEvent> data;

            private boolean done;

            private Complement(final Dataset left,
                final Collection<JrubyEventExtLibrary.RubyEvent> complement) {
                this.left = left;
                data = complement;
            }

            @Override
            public Collection<JrubyEventExtLibrary.RubyEvent> compute(
                final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
                final RubyHash options) {
                if (done) {
                    return data;
                }
                left.compute(batch, flush, shutdown, options);
                done = true;
                return data;
            }

            @Override
            public void clear() {
                left.clear();
                data.clear();
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
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
            final RubyHash options) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(batch, flush, shutdown, options));
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
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
            final RubyHash options) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(batch, flush, shutdown, options));
            }
            done = true;
            data.addAll(func.multiFilter(buffer));
            if (flush) {
                data.addAll(func.flush(options));
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
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final RubyIntegration.Batch batch, final boolean flush, final boolean shutdown,
            final RubyHash options) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(batch, flush, shutdown, options));
            }
            done = true;
            data.addAll(func.multiFilter(buffer));
            if (flush && shutdown) {
                data.addAll(func.flush(options));
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

    /**
     * Output {@link Dataset} that passes all its {@link JrubyEventExtLibrary.RubyEvent}
     * to the underlying {@link RubyIntegration.Output#multiReceive(Collection)}.
     */
    final class OutputDataset implements Dataset {

        private final Collection<Dataset> parents;

        private final RubyIntegration.Output output;

        private final Collection<JrubyEventExtLibrary.RubyEvent> data;

        private final Collection<JrubyEventExtLibrary.RubyEvent> buffer;

        private boolean done;

        public OutputDataset(Collection<Dataset> parents, final RubyIntegration.Output output) {
            this.parents = parents;
            this.output = output;
            data = new ArrayList<>(5);
            buffer = new ArrayList<>(5);
            done = false;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final RubyIntegration.Batch batch,
            final boolean flush, final boolean shutdown, final RubyHash options) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(batch, flush, shutdown, options));
            }
            output.multiReceive(buffer);
            data.addAll(buffer);
            done = true;
            buffer.clear();
            for (final JrubyEventExtLibrary.RubyEvent event : data) {
                batch.merge(event);
            }
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
