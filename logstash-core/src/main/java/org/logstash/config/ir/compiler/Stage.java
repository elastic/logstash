package org.logstash.config.ir.compiler;

import java.util.Collection;
import org.logstash.config.ir.PipelineIR;
import org.logstash.ext.JrubyEventExtLibrary;

public interface Stage {

    void flushAndExecute(RubyIntegration.Batch batch);

    void execute(RubyIntegration.Batch batch);

    final class Compiler {

        public static Stage compileFull(final PipelineIR java,
            final RubyIntegration.Pipeline ruby) {
            return new Stage.Compiler.FullStage();
        }

        public static Stage compileFilter(final PipelineIR java,
            final RubyIntegration.Pipeline ruby,
            final Collection<JrubyEventExtLibrary.RubyEvent> buffer) {
            return new Stage.Compiler.FilterStage();
        }

        private static final class FullStage implements Stage {

            public FullStage() {
            }

            @Override
            public void flushAndExecute(final RubyIntegration.Batch batch) {
            }

            @Override
            public void execute(final RubyIntegration.Batch batch) {
            }
        }

        private static final class FilterStage implements Stage {

            @Override
            public void flushAndExecute(final RubyIntegration.Batch batch) {
            }

            @Override
            public void execute(final RubyIntegration.Batch batch) {
                boolean meh = false;
                meh |= true;
            }
        }
    }

}
