package org.logstash.log;

import co.elastic.logstash.api.*;

import java.io.IOException;
import java.io.OutputStream;
import java.nio.ByteBuffer;
import java.util.Collection;
import java.util.Map;
import java.util.function.Consumer;

@LogstashPlugin(name = "java_deprecation_plugin")
public class TestingDeprecationPlugin implements Codec {

    private final DeprecationLogger deprecationLogger;

    /**
     * Required constructor.
     *
     * @param configuration Logstash Configuration
     * @param context       Logstash Context
     */
    public TestingDeprecationPlugin(final Configuration configuration, final Context context) {
        deprecationLogger = context.getDeprecationLogger(this);
    }

    @Override
    public Collection<PluginConfigSpec<?>> configSchema() {
        return null;
    }

    @Override
    public String getId() {
        return null;
    }

    @Override
    public void decode(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {

    }

    @Override
    public void flush(ByteBuffer buffer, Consumer<Map<String, Object>> eventConsumer) {

    }

    @Override
    public void encode(Event event, OutputStream output) throws IOException {
        deprecationLogger.deprecated("Deprecated feature {}", "teleportation");
    }

    @Override
    public Codec cloneCodec() {
        return null;
    }
}
