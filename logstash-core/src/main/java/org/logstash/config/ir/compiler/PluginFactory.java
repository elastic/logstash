package org.logstash.config.ir.compiler;

import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.execution.Filter;
import org.logstash.execution.Input;
import org.logstash.execution.LsConfiguration;
import org.logstash.execution.LsContext;

/**
 * Factory that can instantiate Java plugins as well as Ruby plugins.
 */
public interface PluginFactory extends RubyIntegration.PluginFactory {

    Input buildInput(String name, String id, LsConfiguration configuration, LsContext context);

    org.logstash.execution.Filter buildFilter(
        String name, String id, LsConfiguration configuration, LsContext context
    );

    final class Default implements PluginFactory {

        private final RubyIntegration.PluginFactory rubyFactory;

        public Default(final RubyIntegration.PluginFactory rubyFactory) {
            this.rubyFactory = rubyFactory;
        }

        @Override
        public Input buildInput(final String name, final String id, final LsConfiguration configuration, final LsContext context) {
            return null;
        }

        @Override
        public Filter buildFilter(final String name, final String id, final LsConfiguration configuration, final LsContext context) {
            return null;
        }

        @Override
        public IRubyObject buildInput(final RubyString name, final RubyInteger line, final RubyInteger column, final IRubyObject args) {
            return rubyFactory.buildInput(name, line, column, args);
        }

        @Override
        public AbstractOutputDelegatorExt buildOutput(final RubyString name, final RubyInteger line, final RubyInteger column, final IRubyObject args) {
            return rubyFactory.buildOutput(name, line, column, args);
        }

        @Override
        public FilterDelegatorExt buildFilter(final RubyString name, final RubyInteger line, final RubyInteger column, final IRubyObject args) {
            return rubyFactory.buildFilter(name, line, column, args);
        }

        @Override
        public IRubyObject buildCodec(final RubyString name, final IRubyObject args) {
            return rubyFactory.buildCodec(name, args);
        }
    }
}
