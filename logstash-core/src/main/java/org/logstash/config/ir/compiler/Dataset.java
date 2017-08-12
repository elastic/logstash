package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.jruby.RubyArray;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

/**
 * A data structure backed by a {@link RubyArray} that is lazily filled with
 * {@link JrubyEventExtLibrary.RubyEvent} computed from its dependencies.
 */
public interface Dataset {

    /**
     * Compute the actual contents of the backing {@link RubyArray} and cache them.
     * Repeated invocations will be effectively free.
     * @param originals Input {@link JrubyEventExtLibrary.RubyEvent} received at the root
     * of the execution
     * @return Computed {@link RubyArray} of {@link JrubyEventExtLibrary.RubyEvent}
     */
    RubyArray compute(RubyArray originals);

    /**
     * {@link Dataset} that contains all {@link JrubyEventExtLibrary.RubyEvent} of all of
     * its dependencies.
     */
    final class SumDataset implements Dataset {
        private final Collection<Dataset> parents;

        public SumDataset(final Collection<Dataset> parents) {
            this.parents = parents;
        }

        @Override
        public RubyArray compute(final RubyArray originals) {
            final RubyArray res = RubyUtil.RUBY.newArray();
            parents.forEach(dataset -> res.addAll(dataset.compute(originals)));
            return res;
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

        private final RubyArray data;

        public SplitDataset(Collection<Dataset> parents, final EventCondition func) {
            this.parents = parents;
            this.func = func;
            done = false;
            data = RubyUtil.RUBY.newArray();
        }

        @Override
        public RubyArray compute(final RubyArray originals) {
            if (done) {
                return data;
            }
            for (final Dataset set : parents) {
                for (final Object event : set.compute(originals)) {
                    if (func.fulfilled((JrubyEventExtLibrary.RubyEvent) event)) {
                        data.add(event);
                    }
                }
            }
            done = true;
            return data;
        }
    }

    final class RootDataset implements Dataset {

        @Override
        public RubyArray compute(final RubyArray originals) {
            return originals;
        }
    }

    /**
     * {@link Dataset} resulting from applying a backing {@link RubyIntegration.Filter} to all
     * dependent {@link Dataset}.
     */
    final class FilteredDataset implements Dataset {

        private final Collection<Dataset> parents;

        private final RubyIntegration.Filter func;

        private final RubyArray data;

        private boolean done;

        public FilteredDataset(Collection<Dataset> parents, final RubyIntegration.Filter func) {
            this.parents = parents;
            this.func = func;
            data = RubyUtil.RUBY.newArray();
            done = false;
        }

        @Override
        public RubyArray compute(final RubyArray originals) {
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
    }
}
