package org.logstash.plugins;

import co.elastic.logstash.api.Codec;
import co.elastic.logstash.api.Filter;
import co.elastic.logstash.api.Input;
import co.elastic.logstash.api.Output;
import co.elastic.logstash.api.Plugin;
import org.jruby.RubyClass;
import org.jruby.RubyString;
import org.jruby.java.proxies.JavaProxy;
import org.jruby.javasupport.JavaClass;
import org.jruby.runtime.builtin.IRubyObject;
import org.logstash.RubyUtil;
import org.logstash.plugins.discovery.PluginRegistry;

import java.util.stream.Collectors;
import java.util.stream.Stream;

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

    @SuppressWarnings("rawtypes")
    public static PluginLookup.PluginClass lookup(final PluginLookup.PluginType type, final String name) {
        Class<?> javaClass = PluginRegistry.getPluginClass(type, name);
        if (javaClass != null) {

            if (!PluginValidator.validatePlugin(type, javaClass)) {
                throw new IllegalStateException("Java plugin '" + name + "' is incompatible with the current Logstash plugin API");
            }

            return new PluginLookup.PluginClass() {

                @Override
                public PluginLookup.PluginLanguage language() {
                    return PluginLookup.PluginLanguage.JAVA;
                }

                @Override
                public Object klass() {
                    return javaClass;
                }
            };
        } else {
            Object klass =
                    RUBY_REGISTRY.callMethod(
                            RubyUtil.RUBY.getCurrentContext(), "lookup",
                            new IRubyObject[]{type.rubyLabel(), RubyUtil.RUBY.newString(name)});

            PluginLanguage language = klass instanceof RubyClass
                    ? PluginLanguage.RUBY
                    : PluginLanguage.JAVA;

            klass = (klass instanceof JavaProxy) ? ((JavaProxy) klass).getObject() : klass;

            Object resolvedClass = klass instanceof JavaClass
                    ? ((JavaClass) klass).javaClass()
                    : klass;

            if (language == PluginLanguage.JAVA && !PluginValidator.validatePlugin(type, (Class) resolvedClass)) {
                throw new IllegalStateException("Java plugin '" + name + "' is incompatible with the current Logstash plugin API");
            }

            return new PluginLookup.PluginClass() {
                @Override
                public PluginLookup.PluginLanguage language() {
                    return language;
                }

                @Override
                public Object klass() {
                    return resolvedClass;
                }
            };
        }
    }

    public interface PluginClass {
        PluginLookup.PluginLanguage language();

        Object klass();

        default String toReadableString() {
            return String.format("Plugin class [%s], language [%s]", klass(), language());
        }
    }

    public enum PluginLanguage {
        JAVA, RUBY
    }

    public enum PluginType {
        INPUT("input", Input.class), FILTER("filter", Filter.class), OUTPUT("output", Output.class), CODEC("codec", Codec.class);

        private final String label;
        private final RubyString rubyLabel;
        private final Class<? extends Plugin> pluginClass;

        PluginType(final String label, final Class<? extends Plugin> pluginClass) {
            this.label = label;
            this.rubyLabel = RubyUtil.RUBY.newString(label);
            this.pluginClass = pluginClass;
        }

        public RubyString rubyLabel() {
            return rubyLabel;
        }

        public String label() {
            return label;
        }

        public Class<? extends Plugin> pluginClass() {
            return pluginClass;
        }

        public static PluginType getTypeByPlugin(Plugin plugin) {
            for (final PluginType type : PluginType.values()) {
                if (type.pluginClass().isInstance(plugin)) {
                    return type;
                }
            }

            final String allowedPluginTypes = Stream.of(PluginType.values())
                .map((t) -> t.pluginClass().getName()).collect(Collectors.joining(", "));

            throw new IllegalArgumentException(String.format(
                "Plugin [%s] does not extend one of: %s",
                plugin.getName(),
                allowedPluginTypes
            ));
        }
    }
}
