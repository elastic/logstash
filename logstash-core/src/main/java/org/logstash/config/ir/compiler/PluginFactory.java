package org.logstash.config.ir.compiler;

import org.jruby.RubyInteger;
import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.plugins.api.Filter;
import org.logstash.plugins.api.Input;
import org.logstash.plugins.api.LsConfiguration;
import org.logstash.plugins.api.LsContext;
import org.logstash.plugins.api.Output;
import sun.reflect.generics.reflectiveObjects.NotImplementedException;

/**
 * Factory that can instantiate Java plugins as well as Ruby plugins.
 */
public interface PluginFactory extends RubyIntegration.PluginFactory {

    Input buildInput(String name, String id, LsConfiguration configuration, LsContext context);

    Filter buildFilter(
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
        public AbstractOutputDelegatorExt buildJavaOutput(String name, int line, int column, Output output, IRubyObject args) {
            throw new NotImplementedException();
        }

        @Override
        public AbstractFilterDelegatorExt buildFilter(final RubyString name, final RubyInteger line, final RubyInteger column, final IRubyObject args) {
            return rubyFactory.buildFilter(name, line, column, args);
        }

        @Override
        public AbstractFilterDelegatorExt buildJavaFilter(String name, int line, int column, Filter filter, IRubyObject args) {
            throw new NotImplementedException();
        }

        @Override
        public IRubyObject buildCodec(final RubyString name, final IRubyObject args) {
            return rubyFactory.buildCodec(name, args);
        }
    }
}
