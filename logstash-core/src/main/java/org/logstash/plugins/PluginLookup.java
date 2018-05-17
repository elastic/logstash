package org.logstash.plugins;

import org.jruby.RubyString;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;

/**
 * Java Implementation of the plugin that is implemented by wrapping the Ruby
 * {@code LogStash::Plugin} class for the Ruby plugin lookup.
 */
public final class PluginLookup {

    private static final IRubyObject RUBY_REGISTRY = RubyUtil.RUBY.executeScript(
        "require 'logstash/plugins/registry'\nrequire 'logstash/plugin'\nLogStash::Plugin",
        ""
    );

    private PluginLookup() {
        // Utility Class
    }

    public static PluginLookup.PluginClass lookup(final PluginLookup.PluginType type,
        final String name) {
        return new PluginLookup.PluginClass() {
            @Override
            public PluginLookup.PluginLanguage language() {
                return PluginLookup.PluginLanguage.RUBY;
            }

            @Override
            public Object klass() {
                return RUBY_REGISTRY.callMethod(
                    RubyUtil.RUBY.getCurrentContext(), "lookup",
                    new IRubyObject[]{type.rubyLabel(), RubyUtil.RUBY.newString(name)}
                );
            }
        };
    }

    public interface PluginClass {

        PluginLookup.PluginLanguage language();

        Object klass();
    }

    public enum PluginLanguage {
        JAVA, RUBY
    }

    public enum PluginType {
        INPUT("input"), FILTER("filter"), OUTPUT("output"), CODEC("codec");

        private final RubyString label;

        PluginType(final String label) {
            this.label = RubyUtil.RUBY.newString(label);
        }

        RubyString rubyLabel() {
            return label;
        }
    }
}
