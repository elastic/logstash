package org.logstash.config.ir.compiler;

public interface Stage {

    void flushAndExecute(RubyIntegration.Batch batch);

    void execute(RubyIntegration.Batch batch);

    final class Compiler {

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
