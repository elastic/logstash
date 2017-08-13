package org.logstash.config.ir.compiler;

import java.util.ArrayList;
import java.util.Collection;
import java.util.Collections;
import org.jruby.RubyArray;
import org.logstash.RubyUtil;
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
     * @param originals Input {@link JrubyEventExtLibrary.RubyEvent} received at the root
     * of the execution
     * @return Computed {@link RubyArray} of {@link JrubyEventExtLibrary.RubyEvent}
     */
    Collection<JrubyEventExtLibrary.RubyEvent> compute(
        Collection<JrubyEventExtLibrary.RubyEvent> originals);

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
                final Collection<JrubyEventExtLibrary.RubyEvent> originals) {
                return originals;
            }

            @Override
            public void clear() {
            }
        }
    );

    /**
     * {@link Dataset} that contains all {@link JrubyEventExtLibrary.RubyEvent} of all of
     * its dependencies.
     */
    final class SumDataset implements Dataset {

        /**
         * Trivial {@link Dataset} that simply returns an empty collection of elements.
         */
        private static final Dataset TRIVIAL = new Dataset() {

            @Override
            public Collection<JrubyEventExtLibrary.RubyEvent> compute(
                final Collection<JrubyEventExtLibrary.RubyEvent> originals) {
                return Collections.emptyList();
            }

            @Override
            public void clear() {
            }
        };

        private final Collection<Dataset> parents;

        /**
         * <p>Builds sum of the given parent {@link Dataset}. If the given parent {@link Dataset}
         * collection only contains a single {@link Dataset}, then that one {@link Dataset} will
         * be returned since no summation is necessary.</p>
         * <p>If the given set of parent {@link Dataset} is empty the sum is defined as the
         * trivial dataset that simply passes given inputs through without change.</p>
         * @param parents Parent {@link Dataset} to sum
         * @return Dataset representing the sum of given parent {@link Dataset}
         */
        public static Dataset from(final Collection<Dataset> parents) {
            final int count = parents.size();
            final Dataset result;
            if (count > 1) {
                result = new Dataset.SumDataset(parents);
            } else if (count == 1) {
                result = parents.iterator().next();
            } else {
                result = TRIVIAL;
            }
            return result;
        }

        private SumDataset(final Collection<Dataset> parents) {
            this.parents = parents;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final Collection<JrubyEventExtLibrary.RubyEvent> originals) {
            final RubyArray res = RubyUtil.RUBY.newArray();
            parents.forEach(dataset -> res.addAll(dataset.compute(originals)));
            return res;
        }

        @Override
        public void clear() {
            for (final Dataset parent : parents) {
                parent.clear();
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

        private boolean done;

        private final Collection<JrubyEventExtLibrary.RubyEvent> data;

        public SplitDataset(Collection<Dataset> parents, final EventCondition func) {
            this.parents = parents;
            this.func = func;
            done = false;
            data = new ArrayList<>(5);
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final Collection<JrubyEventExtLibrary.RubyEvent> originals) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                for (final JrubyEventExtLibrary.RubyEvent event : set.compute(originals)) {
                    if (func.fulfilled(event)) {
                        data.add(event);
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
            done = false;
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

        private boolean done;

        public FilteredDataset(Collection<Dataset> parents, final RubyIntegration.Filter func) {
            this.parents = parents;
            this.func = func;
            data = new ArrayList<>(5);
            done = false;
        }

        @Override
        public Collection<JrubyEventExtLibrary.RubyEvent> compute(
            final Collection<JrubyEventExtLibrary.RubyEvent> originals) {
            if (done) {
                return data;
            }
            final RubyArray buffer = RubyUtil.RUBY.newArray();
            for (final Dataset set : parents) {
                buffer.addAll(set.compute(originals));
            }
            done = true;
            data.addAll(func.multiFilter(buffer));
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
