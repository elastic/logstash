package org.logstash.plugins.api;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import org.logstash.Event;

/**
 * A Logstash Filter.
 */
public interface Filter extends LsPlugin {

    Collection<Event> filter(Collection<Event> events);

    @LogstashPlugin(name = "mutate")
    final class Mutate implements Filter {

        private static final PluginConfigSpec<String> FIELD_CONFIG =
            LsConfiguration.requiredStringSetting("field");

        private static final PluginConfigSpec<String> VALUE_CONFIG =
            LsConfiguration.requiredStringSetting("value");

        private final String field;

        private final String value;

        /**
         * Required Constructor Signature only taking a {@link LsConfiguration}.
         * @param configuration Logstash Configuration
         * @param context Logstash Context
         */
        public Mutate(final LsConfiguration configuration, final LsContext context) {
            this.field = configuration.get(FIELD_CONFIG);
            this.value = configuration.get(VALUE_CONFIG);
        }

        @Override
        public Collection<Event> filter(final Collection<Event> events) {
            //TODO: Impl.
            return events;
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return Arrays.asList(FIELD_CONFIG, VALUE_CONFIG);
        }
    }

    @LogstashPlugin(name = "java-clone")
    final class Clone implements Filter {

        private Event clone;

        private long lastSeq = -1L;

        /**
         * Required Constructor Signature only taking a {@link LsConfiguration}.
         * @param configuration Logstash Configuration
         * @param context Logstash Context
         */
        public Clone(final LsConfiguration configuration, final LsContext context) {
        }

        @Override
        public Collection<Event> filter(final Collection<Event> events) {
            for (Event e : events) {
                e.setField("java-clone", "was here");
            }
            return events;
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return Collections.emptyList();
        }
    }
}
