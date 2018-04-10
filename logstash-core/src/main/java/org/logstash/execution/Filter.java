package org.logstash.execution;

import java.util.Arrays;
import java.util.Collection;
import java.util.Collections;
import org.logstash.Event;

/**
 * A Filter is simply a mapping of {@link QueueReader} to a new {@link QueueReader}.
 */
public interface Filter extends LsPlugin {

    QueueReader filter(QueueReader reader);

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
        public QueueReader filter(final QueueReader reader) {
            return new QueueReader() {
                @Override
                public long poll(final Event event) {
                    final long seq = reader.poll(event);
                    if (seq > -1L) {
                        event.setField(field, value);
                    }
                    return seq;
                }

                @Override
                public long poll(final Event event, final long millis) {
                    final long seq = reader.poll(event, millis);
                    if (seq > -1L) {
                        event.setField(field, value);
                    }
                    return seq;
                }

                @Override
                public void acknowledge(final long sequenceNum) {
                    reader.acknowledge(sequenceNum);
                }
            };
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return Arrays.asList(FIELD_CONFIG, VALUE_CONFIG);
        }
    }

    @LogstashPlugin(name = "clone")
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
        public QueueReader filter(final QueueReader reader) {
            return new QueueReader() {
                @Override
                public long poll(final Event event) {
                    if (clone != null) {
                        event.overwrite(clone);
                        clone = null;
                        return lastSeq;
                    }
                    final long seq = reader.poll(event);
                    lastSeq = seq;
                    if (seq > -1L) {
                        clone = event.clone();
                    }
                    return seq;
                }

                @Override
                public long poll(final Event event, final long millis) {
                    if (clone != null) {
                        event.overwrite(clone);
                        clone = null;
                        return lastSeq;
                    }
                    final long seq = reader.poll(event, millis);
                    lastSeq = seq;
                    if (seq > -1L) {
                        clone = event.clone();
                    }
                    return seq;
                }

                @Override
                public void acknowledge(final long sequenceNum) {
                    reader.acknowledge(sequenceNum);
                }
            };
        }

        @Override
        public Collection<PluginConfigSpec<?>> configSchema() {
            return Collections.emptyList();
        }
    }
}
