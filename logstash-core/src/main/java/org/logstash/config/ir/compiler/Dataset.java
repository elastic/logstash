package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.jruby.RubyArray;
import org.logstash.RubyUtil;
import org.logstash.ext.JrubyEventExtLibrary;

public interface Dataset {

    RubyArray compute(RubyArray originals);

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

    final class FilteredDataset implements Dataset {

        private final Collection<Dataset> parents;

        private final RubyIntegration.Filter func;

        private final RubyArray data;

        private boolean done;

        public FilteredDataset(Collection<Dataset> parents,
            final RubyIntegration.Filter func) {
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
